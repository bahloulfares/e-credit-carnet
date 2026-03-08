import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import transactionService from '../services/transactionService';
import logger from '../utils/logger';import { convertDecimalsToNumbers } from '../utils/decimal';
export class TransactionController {
  async createTransaction(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { clientId, type, amount, description, dueDate, paymentMethod } = req.body;

      if (!clientId || !type || !amount) {
        res.status(400).json({ error: 'Missing required fields' });
        return;
      }

      if (!['CREDIT', 'PAYMENT'].includes(type)) {
        res.status(400).json({ error: 'Invalid transaction type' });
        return;
      }

      const transaction = await transactionService.createTransaction(
        req.user.id,
        clientId,
        {
          type,
          amount,
          description,
          dueDate: dueDate ? new Date(dueDate) : undefined,
          paymentMethod,
        },
      );

      logger.info(`Transaction created: ${transaction.id}`);
      res.status(201).json({
        message: 'Transaction created successfully',
        transaction,
      });
    } catch (error) {
      logger.error('Create transaction error:', error);
      if (error instanceof Error && error.message === 'Client not found') {
        res.status(404).json({ error: 'Client not found' });
      } else {
        res.status(500).json({ error: 'Failed to create transaction' });
      }
    }
  }

  async getTransactions(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { clientId } = req.query;
      const skip = parseInt(req.query.skip as string) || 0;
      const take = parseInt(req.query.take as string) || 20;

      const transactions = await transactionService.listTransactions(
        req.user.id,
        clientId as string,
        {
          skip,
          take,
        },
      );

      res.status(200).json({
        transactions: convertDecimalsToNumbers(transactions),
        skip,
        take,
      });
    } catch (error) {
      logger.error('Get transactions error:', error);
      res.status(500).json({ error: 'Failed to get transactions' });
    }
  }

  async getTransactionById(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { id } = req.params;
      const transaction = await transactionService.getTransactionById(id, req.user.id);

      if (!transaction) {
        res.status(404).json({ error: 'Transaction not found' });
        return;
      }

      res.status(200).json({ transaction: convertDecimalsToNumbers(transaction) });
    } catch (error) {
      logger.error('Get transaction error:', error);
      res.status(500).json({ error: 'Failed to get transaction' });
    }
  }

  async updateTransaction(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { id } = req.params;
      const { description, dueDate, paymentMethod } = req.body;

      const transaction = await transactionService.updateTransaction(id, req.user.id, {
        description,
        dueDate: dueDate ? new Date(dueDate) : undefined,
        paymentMethod,
      });

      logger.info(`Transaction updated: ${id}`);
      res.status(200).json({
        message: 'Transaction updated successfully',
        transaction: convertDecimalsToNumbers(transaction),
      });
    } catch (error) {
      logger.error('Update transaction error:', error);
      if (error instanceof Error && error.message === 'Transaction not found') {
        res.status(404).json({ error: 'Transaction not found' });
      } else {
        res.status(500).json({ error: 'Failed to update transaction' });
      }
    }
  }

  async deleteTransaction(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { id } = req.params;
      await transactionService.deleteTransaction(id, req.user.id);

      logger.info(`Transaction deleted: ${id}`);
      res.status(200).json({ message: 'Transaction deleted successfully' });
    } catch (error) {
      logger.error('Delete transaction error:', error);
      if (error instanceof Error && error.message === 'Transaction not found') {
        res.status(404).json({ error: 'Transaction not found' });
      } else {
        res.status(500).json({ error: 'Failed to delete transaction' });
      }
    }
  }

  async markAsPaid(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { id } = req.params;
      const { paymentMethod } = req.body;

      const transaction = await transactionService.markAsPaid(
        id,
        req.user.id,
        paymentMethod,
      );

      logger.info(`Transaction marked as paid: ${id}`);
      res.status(200).json({
        message: 'Transaction marked as paid',
        transaction: convertDecimalsToNumbers(transaction),
      });
    } catch (error) {
      logger.error('Mark as paid error:', error);
      if (error instanceof Error && error.message === 'Transaction not found') {
        res.status(404).json({ error: 'Transaction not found' });
      } else {
        res.status(500).json({ error: 'Failed to mark transaction as paid' });
      }
    }
  }
}

export default new TransactionController();
