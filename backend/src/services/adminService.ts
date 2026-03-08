import { PrismaClient } from '@prisma/client';
import { ApiError } from '../utils/errors';
import { hashPassword } from '../utils/bcrypt';

const prisma = new PrismaClient();

export interface AdminEpicierSummary {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  shopName: string | null;
  isActive: boolean;
  subscriptionStatus: string;
  createdAt: Date;
  clientsCount: number;
  transactionsCount: number;
}

export interface AdminGlobalStats {
  totalEpiciers: number;
  activeEpiciers: number;
  totalClients: number;
  totalTransactions: number;
  totalCredit: number;
  totalPayment: number;
  totalDebt: number;
  monthlyTransactions: number;
  monthlyCredit: number;
  monthlyPayment: number;
}

class AdminService {
  async getGlobalStats(): Promise<AdminGlobalStats> {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const baseTxWhere = {
      deletedAt: null as null,
      user: {
        is: {
          role: 'EPICIER' as const,
        },
      },
      client: {
        is: {
          isActive: true,
        },
      },
    };

    const [
      totalEpiciers,
      activeEpiciers,
      totalClients,
      totalTransactions,
      totalCreditAgg,
      totalPaymentAgg,
      monthlyTransactions,
      monthlyCreditAgg,
      monthlyPaymentAgg,
      debtByClient,
    ] = await Promise.all([
      prisma.user.count({
        where: { role: 'EPICIER' },
      }),
      prisma.user.count({
        where: { role: 'EPICIER', isActive: true },
      }),
      prisma.client.count({
        where: {
          isActive: true,
          user: {
            is: {
              role: 'EPICIER',
            },
          },
        },
      }),
      prisma.transaction.count({
        where: baseTxWhere,
      }),
      prisma.transaction.aggregate({
        where: {
          ...baseTxWhere,
          type: 'CREDIT',
        },
        _sum: { amount: true },
      }),
      prisma.transaction.aggregate({
        where: {
          ...baseTxWhere,
          type: 'PAYMENT',
        },
        _sum: { amount: true },
      }),
      prisma.transaction.count({
        where: {
          ...baseTxWhere,
          transactionDate: {
            gte: startOfMonth,
          },
        },
      }),
      prisma.transaction.aggregate({
        where: {
          ...baseTxWhere,
          type: 'CREDIT',
          transactionDate: {
            gte: startOfMonth,
          },
        },
        _sum: { amount: true },
      }),
      prisma.transaction.aggregate({
        where: {
          ...baseTxWhere,
          type: 'PAYMENT',
          transactionDate: {
            gte: startOfMonth,
          },
        },
        _sum: { amount: true },
      }),
      prisma.transaction.groupBy({
        by: ['clientId', 'type'],
        where: baseTxWhere,
        _sum: { amount: true },
      }),
    ]);

    const debtMap = new Map<string, { credit: number; payment: number }>();
    for (const row of debtByClient) {
      const current = debtMap.get(row.clientId) ?? { credit: 0, payment: 0 };
      if (row.type === 'CREDIT') {
        current.credit += Number(row._sum.amount ?? 0);
      } else if (row.type === 'PAYMENT') {
        current.payment += Number(row._sum.amount ?? 0);
      }
      debtMap.set(row.clientId, current);
    }

    const totalDebt = Array.from(debtMap.values()).reduce(
      (sum, value) => sum + Math.max(0, value.credit - value.payment),
      0,
    );

    return {
      totalEpiciers,
      activeEpiciers,
      totalClients,
      totalTransactions,
      totalCredit: Number(totalCreditAgg._sum.amount ?? 0),
      totalPayment: Number(totalPaymentAgg._sum.amount ?? 0),
      totalDebt,
      monthlyTransactions,
      monthlyCredit: Number(monthlyCreditAgg._sum.amount ?? 0),
      monthlyPayment: Number(monthlyPaymentAgg._sum.amount ?? 0),
    };
  }

  async listEpiciers(params?: {
    search?: string;
    skip?: number;
    take?: number;
  }): Promise<AdminEpicierSummary[]> {
    const search = params?.search?.trim();

    const users = await prisma.user.findMany({
      where: {
        role: 'EPICIER',
        ...(search
          ? {
              OR: [
                { email: { contains: search } },
                { firstName: { contains: search } },
                { lastName: { contains: search } },
                { shopName: { contains: search } },
              ],
            }
          : {}),
      },
      skip: params?.skip,
      take: params?.take ?? 50,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        shopName: true,
        isActive: true,
        subscriptionStatus: true,
        createdAt: true,
        _count: {
          select: {
            clients: true,
            transactions: true,
          },
        },
      },
    });

    return users.map((user) => ({
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      phone: user.phone,
      shopName: user.shopName,
      isActive: user.isActive,
      subscriptionStatus: user.subscriptionStatus,
      createdAt: user.createdAt,
      clientsCount: user._count.clients,
      transactionsCount: user._count.transactions,
    }));
  }

  async getEpicierById(epicierId: string): Promise<AdminEpicierSummary> {
    const user = await prisma.user.findFirst({
      where: {
        id: epicierId,
        role: 'EPICIER',
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        shopName: true,
        isActive: true,
        subscriptionStatus: true,
        createdAt: true,
        _count: {
          select: {
            clients: true,
            transactions: true,
          },
        },
      },
    });

    if (!user) {
      throw new ApiError(404, 'Epicier not found');
    }

    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      phone: user.phone,
      shopName: user.shopName,
      isActive: user.isActive,
      subscriptionStatus: user.subscriptionStatus,
      createdAt: user.createdAt,
      clientsCount: user._count.clients,
      transactionsCount: user._count.transactions,
    };
  }

  async listEpicierClients(epicierId: string, params?: { skip?: number; take?: number }) {
    const epicier = await prisma.user.findFirst({
      where: { id: epicierId, role: 'EPICIER' },
      select: { id: true },
    });

    if (!epicier) {
      throw new ApiError(404, 'Epicier not found');
    }

    const clients = await prisma.client.findMany({
      where: {
        userId: epicierId,
        isActive: true,
      },
      skip: params?.skip,
      take: params?.take ?? 50,
      orderBy: { createdAt: 'desc' },
    });

    return clients;
  }

  async setEpicierActiveStatus(epicierId: string, isActive: boolean) {
    const epicier = await prisma.user.findFirst({
      where: { id: epicierId, role: 'EPICIER' },
      select: { id: true },
    });

    if (!epicier) {
      throw new ApiError(404, 'Epicier not found');
    }

    const updated = await prisma.user.update({
      where: { id: epicierId },
      data: { isActive },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        isActive: true,
      },
    });

    return updated;
  }

  async resetEpicierPassword(epicierId: string, newPassword: string) {
    const epicier = await prisma.user.findFirst({
      where: { id: epicierId, role: 'EPICIER' },
      select: { id: true },
    });

    if (!epicier) {
      throw new ApiError(404, 'Epicier not found');
    }

    const password = await hashPassword(newPassword);

    await prisma.user.update({
      where: { id: epicierId },
      data: { password },
      select: { id: true },
    });

    return { id: epicierId };
  }
}

export default new AdminService();
