import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { PrismaClient } from '@prisma/client';
import logger from '../utils/logger';
import { convertDecimalsToNumbers } from '../utils/decimal';

const prisma = new PrismaClient();

export class DashboardController {
  async getStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      // Get total clients
      const totalClients = await prisma.client.count({
        where: {
          userId: req.user.id,
          isActive: true,
        },
      });

      // Get total debt
      const clientStats = await prisma.client.aggregate({
        where: {
          userId: req.user.id,
          isActive: true,
        },
        _sum: {
          totalDebt: true,
          totalCredit: true,
          totalPayment: true,
        },
      });

      // Get recent transactions
      const recentTransactions = await prisma.transaction.findMany({
        where: {
          userId: req.user.id,
          deletedAt: null,
          client: {
            is: {
              isActive: true,
            },
          },
        },
        include: {
          client: {
            select: {
              firstName: true,
              lastName: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: 5,
      });

      // Get this month's stats
      const startOfMonth = new Date();
      startOfMonth.setDate(1);
      startOfMonth.setHours(0, 0, 0, 0);

      const monthlyStats = await prisma.transaction.aggregate({
        where: {
          userId: req.user.id,
          client: {
            is: {
              isActive: true,
            },
          },
          transactionDate: {
            gte: startOfMonth,
          },
          deletedAt: null,
        },
        _count: true,
      });

      const monthlyCreditStats = await prisma.transaction.aggregate({
        where: {
          userId: req.user.id,
          type: 'CREDIT',
          client: {
            is: {
              isActive: true,
            },
          },
          transactionDate: {
            gte: startOfMonth,
          },
          deletedAt: null,
        },
        _sum: {
          amount: true,
        },
      });

      const monthlyPaymentStats = await prisma.transaction.aggregate({
        where: {
          userId: req.user.id,
          type: 'PAYMENT',
          client: {
            is: {
              isActive: true,
            },
          },
          transactionDate: {
            gte: startOfMonth,
          },
          deletedAt: null,
        },
        _sum: {
          amount: true,
        },
      });

      const stats = {
        totalClients,
        totalDebt: clientStats._sum.totalDebt || 0,
        totalCredit: clientStats._sum.totalCredit || 0,
        totalPayment: clientStats._sum.totalPayment || 0,
        monthlyTransactions: monthlyStats._count,
        monthlyCredit: monthlyCreditStats._sum.amount || 0,
        monthlyPayment: monthlyPaymentStats._sum.amount || 0,
        recentTransactions,
      };

      res.status(200).json({ stats: convertDecimalsToNumbers(stats) });
    } catch (error) {
      logger.error('Get stats error:', error);
      res.status(500).json({ error: 'Failed to get dashboard stats' });
    }
  }

  async getSyncStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      // Get pending syncs
      const pendingSyncs = await prisma.pendingSync.count({
        where: {
          userId: req.user.id,
          syncStatus: 'PENDING',
        },
      });

      // Get last sync log
      const lastSyncLog = await prisma.syncLog.findFirst({
        where: {
          userId: req.user.id,
        },
        orderBy: { syncStartTime: 'desc' },
      });

      res.status(200).json({
        pendingSyncs,
        lastSync: lastSyncLog,
      });
    } catch (error) {
      logger.error('Get sync status error:', error);
      res.status(500).json({ error: 'Failed to get sync status' });
    }
  }
}

export default new DashboardController();
