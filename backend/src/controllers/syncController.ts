import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { TransactionType } from '@prisma/client';
import logger from '../utils/logger';
import prisma from '../lib/prisma';

interface SyncData extends Record<string, unknown> {
  id: string;
  [key: string]: unknown;
}

export class SyncController {
  async sync(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { changes } = req.body;

      if (!changes || !Array.isArray(changes)) {
        res.status(400).json({ error: 'Changes array is required' });
        return;
      }

      const syncLog = await prisma.syncLog.create({
        data: {
          userId: req.user.id,
          status: 'in_progress',
          deviceInfo: req.headers['user-agent'],
        },
      });

      let itemsSynced = 0;
      let itemsFailed = 0;
      const errors: string[] = [];

      // Process each change
      for (const change of changes) {
        try {
          const { entityType, entityId, operationType, data } = change;

          if (entityType === 'client') {
            await this.syncClient(entityType, operationType, entityId, data, req.user.id);
          } else if (entityType === 'transaction') {
            await this.syncTransaction(entityType, operationType, entityId, data, req.user.id);
          }

          itemsSynced++;
        } catch (error) {
          itemsFailed++;
          if (error instanceof Error) {
            errors.push(error.message);
          }
        }
      }

      // Update sync log
      await prisma.syncLog.update({
        where: { id: syncLog.id },
        data: {
          syncEndTime: new Date(),
          status: itemsFailed === 0 ? 'success' : 'partial',
          itemsSynced,
          itemsFailed,
          errorMessage: errors.length > 0 ? errors.join(', ') : null,
        },
      });

      // Mark pending syncs as synced
      await prisma.pendingSync.updateMany({
        where: {
          userId: req.user.id,
          syncStatus: 'PENDING',
        },
        data: {
          syncStatus: 'SYNCED',
          syncedAt: new Date(),
        },
      });

      logger.info(`Sync completed for user ${req.user.id}: ${itemsSynced} synced, ${itemsFailed} failed`);

      res.status(200).json({
        message: 'Sync completed',
        itemsSynced,
        itemsFailed,
        errors: errors.length > 0 ? errors : undefined,
      });
    } catch (error) {
      logger.error('Sync error:', error);
      res.status(500).json({ error: 'Sync failed' });
    }
  }

  private async syncClient(
    entityType: string,
    operationType: string,
    entityId: string,
    data: SyncData,
    userId: string,
  ): Promise<void> {
    if (operationType === 'CREATE') {
      await prisma.client.create({
        data: {
          id: data.id as string,
          userId,
          firstName: data.firstName as string,
          lastName: data.lastName as string,
          phone: data.phone as string | undefined,
          email: data.email as string | undefined,
          address: data.address as string | undefined,
        },
      });
    } else if (operationType === 'UPDATE') {
      await prisma.client.update({
        where: { id: entityId },
        data: {
          firstName: data.firstName as string | undefined,
          lastName: data.lastName as string | undefined,
          phone: data.phone as string | null | undefined,
          email: data.email as string | null | undefined,
          address: data.address as string | null | undefined,
        },
      });
    } else if (operationType === 'DELETE') {
      await prisma.client.update({
        where: { id: entityId },
        data: {
          isActive: false,
          deletedAt: new Date(),
        },
      });
    }
  }

  private async syncTransaction(
    entityType: string,
    operationType: string,
    entityId: string,
    data: SyncData,
    userId: string,
  ): Promise<void> {
    if (operationType === 'CREATE') {
      await prisma.transaction.create({
        data: {
          id: data.id as string,
          userId,
          clientId: data.clientId as string,
          type: data.type as TransactionType,
          amount: data.amount as string | number,
          description: data.description as string | undefined,
          transactionDate: data.transactionDate as string | Date | undefined,
          dueDate: data.dueDate as string | Date | null | undefined,
          isPaid: data.isPaid as boolean | undefined,
          paidAt: data.paidAt as string | Date | null | undefined,
          paymentMethod: data.paymentMethod as string | null | undefined,
        },
      });
    } else if (operationType === 'UPDATE') {
      await prisma.transaction.update({
        where: { id: entityId },
        data: {
          description: data.description as string | null | undefined,
          dueDate: data.dueDate as string | Date | null | undefined,
          isPaid: data.isPaid as boolean | undefined,
          paidAt: data.paidAt as string | Date | null | undefined,
          paymentMethod: data.paymentMethod as string | null | undefined,
        },
      });
    } else if (operationType === 'DELETE') {
      await prisma.transaction.update({
        where: { id: entityId },
        data: {
          deletedAt: new Date(),
        },
      });
    }
  }
}

export default new SyncController();
