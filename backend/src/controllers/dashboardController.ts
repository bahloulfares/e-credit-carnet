import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import logger from '../utils/logger';
import { convertDecimalsToNumbers } from '../utils/decimal';
import prisma from '../lib/prisma';

export class DashboardController {
  async getStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      // Get this month's date
      const startOfMonth = new Date();
      startOfMonth.setDate(1);
      startOfMonth.setHours(0, 0, 0, 0);

      // Use Promise.all for parallel queries
      const [
        totalClients,
        clientStats,
        recentTransactions,
        monthlyStats,
        monthlyCreditStats,
        monthlyPaymentStats,
      ] = await Promise.all([
        // Get total clients
        prisma.client.count({
          where: {
            userId: req.user.id,
            isActive: true,
          },
        }),

        // Get total debt
        prisma.client.aggregate({
          where: {
            userId: req.user.id,
            isActive: true,
          },
          _sum: {
            totalDebt: true,
            totalCredit: true,
            totalPayment: true,
          },
        }),

        // Get recent transactions
        prisma.transaction.findMany({
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
        }),

        // Get monthly transaction count
        prisma.transaction.aggregate({
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
        }),

        // Get monthly credit stats
        prisma.transaction.aggregate({
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
        }),

        // Get monthly payment stats
        prisma.transaction.aggregate({
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
        }),
      ]);

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
