import { Client } from '@prisma/client';
import { ApiError } from '../utils/errors';
import prisma from '../lib/prisma';

export class ClientService {
  async createClient(
    userId: string,
    data: {
      firstName: string;
      lastName: string;
      phone?: string;
      email?: string;
      address?: string;
    },
  ): Promise<Client> {
    return prisma.client.create({
      data: {
        userId,
        firstName: data.firstName,
        lastName: data.lastName,
        phone: data.phone,
        email: data.email,
        address: data.address,
      },
    });
  }

  async getClientById(clientId: string, userId: string): Promise<Client | null> {
    return prisma.client.findFirst({
      where: {
        id: clientId,
        userId,
      },
    });
  }

  async listClients(userId: string, options?: { skip?: number; take?: number }): Promise<Client[]> {
    return prisma.client.findMany({
      where: {
        userId,
        isActive: true,
      },
      skip: options?.skip,
      take: options?.take,
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateClient(
    clientId: string,
    userId: string,
    data: Partial<Omit<Client, 'id' | 'userId' | 'createdAt' | 'updatedAt' | 'deletedAt'>>,
  ): Promise<Client> {
    const client = await this.getClientById(clientId, userId);

    if (!client) {
      throw new ApiError(404, 'Client not found');
    }

    return prisma.client.update({
      where: { id: clientId },
      data,
    });
  }

  async deleteClient(clientId: string, userId: string): Promise<Client> {
    const client = await this.getClientById(clientId, userId);

    if (!client) {
      throw new ApiError(404, 'Client not found');
    }

    return prisma.client.update({
      where: { id: clientId },
      data: {
        isActive: false,
        deletedAt: new Date(),
      },
    });
  }

  async getClientWithTransactions(clientId: string, userId: string) {
    const client = await prisma.client.findFirst({
      where: {
        id: clientId,
        userId,
      },
      include: {
        transactions: {
          where: { deletedAt: null },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!client) {
      throw new ApiError(404, 'Client not found');
    }

    return client;
  }

  async searchClients(userId: string, query: string): Promise<Client[]> {
    return prisma.client.findMany({
      where: {
        userId,
        isActive: true,
        OR: [
          { firstName: { contains: query } },
          { lastName: { contains: query } },
          { phone: { contains: query } },
          { email: { contains: query } },
        ],
      },
      take: 10,
    });
  }

  async getClientStats(clientId: string, userId: string) {
    const client = await this.getClientById(clientId, userId);

    if (!client) {
      throw new ApiError(404, 'Client not found');
    }

    return {
      totalDebt: client.totalDebt,
      totalCredit: client.totalCredit,
      totalPayment: client.totalPayment,
    };
  }

  async setClientActiveStatus(clientId: string, userId: string, isActive: boolean): Promise<Client> {
    const client = await this.getClientById(clientId, userId);

    if (!client) {
      throw new ApiError(404, 'Client not found');
    }

    return prisma.client.update({
      where: { id: clientId },
      data: { isActive },
    });
  }
}

export default new ClientService();
