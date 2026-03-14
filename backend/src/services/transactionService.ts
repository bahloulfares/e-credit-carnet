import { Transaction, Prisma, TransactionType } from '@prisma/client';
import { ApiError } from '../utils/errors';
import prisma from '../lib/prisma';

type TransactionWithClient = Transaction & {
  client?: {
    id: string;
    firstName: string;
    lastName: string;
    phone: string | null;
  };
};

export class TransactionService {
  async createTransaction(
    userId: string,
    clientId: string,
    data: {
      type: TransactionType;
      amount: number | string;
      description?: string;
      dueDate?: Date;
      paymentMethod?: string;
    },
  ): Promise<Transaction> {
    // Verify client exists
    const client = await prisma.client.findFirst({
      where: {
        id: clientId,
        userId,
      },
    });

    if (!client) {
      throw new ApiError(404, 'Client not found');
    }

    const transaction = await prisma.transaction.create({
      data: {
        userId,
        clientId,
        type: data.type,
        amount: new Prisma.Decimal(data.amount.toString()),
        description: data.description,
        dueDate: data.dueDate,
        isPaid: data.type === 'PAYMENT',
        paidAt: data.type === 'PAYMENT' ? new Date() : null,
        paymentMethod: data.paymentMethod,
      },
    });

    // Update client stats
    await this.updateClientStats(userId, clientId);

    // Create pending sync for offline-first
    await prisma.pendingSync.create({
      data: {
        userId,
        entityType: 'transaction',
        entityId: transaction.id,
        operationType: 'CREATE',
        data: transaction,
        transactionId: transaction.id,
      },
    });

    return transaction;
  }

  async getTransactionById(
    transactionId: string,
    userId: string,
  ): Promise<TransactionWithClient | null> {
    return prisma.transaction.findFirst({
      where: {
        id: transactionId,
        userId,
      },
      include: {
        client: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            phone: true,
          },
        },
      },
    });
  }

  async listTransactions(
    userId: string,
    clientId?: string,
    options?: { 
      skip?: number; 
      take?: number;
      type?: TransactionType;
      isPaid?: boolean;
      month?: number;
      year?: number;
    },
  ): Promise<TransactionWithClient[]> {
    const whereClause: Prisma.TransactionWhereInput = {
      userId,
      deletedAt: null,
    };

    if (clientId) {
      whereClause.clientId = clientId;
    }

    if (options?.type) {
      whereClause.type = options.type;
    }

    if (options?.isPaid !== undefined) {
      whereClause.isPaid = options.isPaid;
    }

    if (options?.month || options?.year) {
      const filterYear = options.year ?? new Date().getFullYear();
      const filterMonth = options.month;

      const startDate = filterMonth
        ? new Date(filterYear, filterMonth - 1, 1)
        : new Date(filterYear, 0, 1);

      const endDate = filterMonth
        ? new Date(filterYear, filterMonth, 1)
        : new Date(filterYear + 1, 0, 1);

      whereClause.transactionDate = {
        gte: startDate,
        lt: endDate,
      };
    }

    return prisma.transaction.findMany({
      where: whereClause,
      include: {
        client: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            phone: true,
          },
        },
      },
      skip: options?.skip,
      take: options?.take,
      orderBy: { transactionDate: 'desc' },
    });
  }

  async getClientTransactions(
    userId: string,
    clientId: string,
    options?: { skip?: number; take?: number },
  ): Promise<TransactionWithClient[]> {
    return this.listTransactions(userId, clientId, options);
  }

  async updateTransaction(
    transactionId: string,
    userId: string,
    data: {
      amount?: number | string;
      description?: string | null;
      dueDate?: Date | null;
      paymentMethod?: string | null;
      isPaid?: boolean;
      paidAt?: Date | null;
    },
  ): Promise<Transaction> {
    const transaction = await this.getTransactionById(transactionId, userId);

    if (!transaction) {
      throw new ApiError(404, 'Transaction not found');
    }

    const updateData: Prisma.TransactionUpdateInput = {
      ...data,
      amount:
        data.amount !== undefined
          ? new Prisma.Decimal(data.amount.toString())
          : undefined,
    };

    const updated = await prisma.transaction.update({
      where: { id: transactionId },
      data: updateData,
    });

    // Update client stats
    await this.updateClientStats(userId, transaction.clientId);

    // Create pending sync
    await prisma.pendingSync.create({
      data: {
        userId,
        entityType: 'transaction',
        entityId: transactionId,
        operationType: 'UPDATE',
        data: updated,
        transactionId,
      },
    });

    return updated;
  }

  async deleteTransaction(transactionId: string, userId: string): Promise<Transaction> {
    const transaction = await this.getTransactionById(transactionId, userId);

    if (!transaction) {
      throw new ApiError(404, 'Transaction not found');
    }

    const deleted = await prisma.transaction.update({
      where: { id: transactionId },
      data: {
        deletedAt: new Date(),
      },
    });

    // Update client stats
    await this.updateClientStats(userId, transaction.clientId);

    // Create pending sync
    await prisma.pendingSync.create({
      data: {
        userId,
        entityType: 'transaction',
        entityId: transactionId,
        operationType: 'DELETE',
        data: deleted,
        transactionId,
      },
    });

    return deleted;
  }

  async markAsPaid(
    transactionId: string,
    userId: string,
    paymentMethod?: string,
  ): Promise<Transaction> {
    const transaction = await this.getTransactionById(transactionId, userId);

    if (!transaction) {
      throw new ApiError(404, 'Transaction not found');
    }

    if (transaction.type !== 'CREDIT') {
      throw new ApiError(400, 'Only credit transactions can be marked as paid');
    }

    if (transaction.isPaid) {
      throw new ApiError(400, 'Transaction already marked as paid');
    }

    // Marquer le crédit comme payé
    const updated = await prisma.transaction.update({
      where: { id: transactionId },
      data: {
        isPaid: true,
        paidAt: new Date(),
        paymentMethod,
      },
    });

    // Créer automatiquement un PAYMENT correspondant
    await this.createTransaction(
      userId,
      transaction.clientId,
      {
        type: 'PAYMENT' as TransactionType,
        amount: Number(transaction.amount),
        description: `Paiement du crédit ${transaction.description || ''}`.trim(),
        paymentMethod: paymentMethod || 'cash',
      },
    );

    // updateClientStats est déjà appelé dans createTransaction
    return updated;
  }

  private async updateClientStats(userId: string, clientId: string): Promise<void> {
    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        clientId,
        deletedAt: null,
      },
    });

    const totalCredit = transactions
      .filter((t) => t.type === 'CREDIT')
      .reduce((sum, t) => sum + Number(t.amount), 0);

    const totalPayment = transactions
      .filter((t) => t.type === 'PAYMENT')
      .reduce((sum, t) => sum + Number(t.amount), 0);

    const totalDebt = totalCredit - totalPayment;

    await prisma.client.update({
      where: { id: clientId },
      data: {
        totalCredit: new Prisma.Decimal(totalCredit),
        totalPayment: new Prisma.Decimal(totalPayment),
        totalDebt: new Prisma.Decimal(Math.max(0, totalDebt)),
      },
    });
  }
}

export default new TransactionService();
