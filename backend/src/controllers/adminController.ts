import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import adminService from '../services/adminService';
import logger from '../utils/logger';
import { convertDecimalsToNumbers } from '../utils/decimal';

class AdminController {
  async getGlobalStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const stats = await adminService.getGlobalStats();
      res.status(200).json({ stats: convertDecimalsToNumbers(stats) });
    } catch (error) {
      logger.error('Admin get global stats error:', error);
      res.status(500).json({ error: 'Failed to get admin global stats' });
    }
  }

  async getEpiciers(req: AuthRequest, res: Response): Promise<void> {
    try {
      const skip = parseInt((req.query.skip as string) || '0');
      const take = parseInt((req.query.take as string) || '50');
      const search = (req.query.search as string) || undefined;

      const epiciers = await adminService.listEpiciers({
        skip,
        take,
        search,
      });

      res.status(200).json({ epiciers });
    } catch (error) {
      logger.error('Admin get epiciers error:', error);
      res.status(500).json({ error: 'Failed to get epiciers' });
    }
  }

  async getEpicierById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const epicier = await adminService.getEpicierById(id);

      res.status(200).json({ epicier });
    } catch (error) {
      logger.error('Admin get epicier error:', error);
      if (error instanceof Error && error.message.includes('not found')) {
        res.status(404).json({ error: 'Epicier not found' });
        return;
      }
      res.status(500).json({ error: 'Failed to get epicier' });
    }
  }

  async getEpicierClients(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const skip = parseInt((req.query.skip as string) || '0');
      const take = parseInt((req.query.take as string) || '50');

      const clients = await adminService.listEpicierClients(id, { skip, take });

      res.status(200).json({ clients: convertDecimalsToNumbers(clients) });
    } catch (error) {
      logger.error('Admin get epicier clients error:', error);
      if (error instanceof Error && error.message.includes('not found')) {
        res.status(404).json({ error: 'Epicier not found' });
        return;
      }
      res.status(500).json({ error: 'Failed to get epicier clients' });
    }
  }

  async updateEpicierStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { isActive } = req.body;

      if (typeof isActive !== 'boolean') {
        res.status(400).json({ error: 'isActive must be a boolean' });
        return;
      }

      const updatedEpicier = await adminService.setEpicierActiveStatus(id, isActive);

      res.status(200).json({
        message: isActive ? 'Epicier account activated' : 'Epicier account deactivated',
        epicier: updatedEpicier,
      });
    } catch (error) {
      logger.error('Admin update epicier status error:', error);
      if (error instanceof Error && error.message.includes('not found')) {
        res.status(404).json({ error: 'Epicier not found' });
        return;
      }
      res.status(500).json({ error: 'Failed to update epicier status' });
    }
  }

  async resetEpicierPassword(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { newPassword } = req.body;

      if (!newPassword || typeof newPassword !== 'string' || newPassword.length < 8) {
        res.status(400).json({ error: 'newPassword must be at least 8 characters' });
        return;
      }

      await adminService.resetEpicierPassword(id, newPassword);

      res.status(200).json({
        message: 'Epicier password reset successfully',
      });
    } catch (error) {
      logger.error('Admin reset epicier password error:', error);
      if (error instanceof Error && error.message.includes('not found')) {
        res.status(404).json({ error: 'Epicier not found' });
        return;
      }
      res.status(500).json({ error: 'Failed to reset epicier password' });
    }
  }

  async createEpicier(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { email, firstName, lastName, password, phone, shopName } = req.body;

      // Validation
      if (!email || !firstName || !lastName || !password) {
        res.status(400).json({ error: 'email, firstName, lastName, and password are required' });
        return;
      }

      if (password.length < 8) {
        res.status(400).json({ error: 'password must be at least 8 characters' });
        return;
      }

      const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
      if (!emailRegex.test(email)) {
        res.status(400).json({ error: 'Invalid email format' });
        return;
      }

      const newEpicier = await adminService.createEpicier({
        email,
        firstName,
        lastName,
        password,
        phone,
        shopName,
      });

      res.status(201).json({
        message: 'Epicier created successfully',
        epicier: newEpicier,
      });
    } catch (error) {
      logger.error('Admin create epicier error:', error);
      if (error instanceof Error && error.message.includes('already exists')) {
        res.status(400).json({ error: 'Email already exists' });
        return;
      }
      res.status(500).json({ error: 'Failed to create epicier' });
    }
  }

  async updateEpicier(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { firstName, lastName, phone, shopName } = req.body;

      const updated = await adminService.updateEpicier(id, {
        firstName,
        lastName,
        phone,
        shopName,
      });

      res.status(200).json({
        message: 'Epicier updated successfully',
        epicier: updated,
      });
    } catch (error) {
      logger.error('Admin update epicier error:', error);
      if (error instanceof Error && error.message.includes('not found')) {
        res.status(404).json({ error: 'Epicier not found' });
        return;
      }
      res.status(500).json({ error: 'Failed to update epicier' });
    }
  }
}

export default new AdminController();
