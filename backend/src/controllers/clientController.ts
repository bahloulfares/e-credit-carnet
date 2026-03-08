import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import clientService from '../services/clientService';
import logger from '../utils/logger';import { convertDecimalsToNumbers } from '../utils/decimal';
export class ClientController {
  async createClient(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { firstName, lastName, phone, email, address } = req.body;

      if (!firstName || !lastName) {
        res.status(400).json({ error: 'First name and last name are required' });
        return;
      }

      const client = await clientService.createClient(req.user.id, {
        firstName,
        lastName,
        phone,
        email,
        address,
      });

      logger.info(`Client created: ${firstName} ${lastName} for user ${req.user.id}`);
      res.status(201).json({
        message: 'Client created successfully',
        client,
      });
    } catch (error) {
      logger.error('Create client error:', error);
      res.status(500).json({ error: 'Failed to create client' });
    }
  }

  async getClients(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const skip = parseInt(req.query.skip as string) || 0;
      const take = parseInt(req.query.take as string) || 10;

      const clients = await clientService.listClients(req.user.id, {
        skip,
        take,
      });

      res.status(200).json({
        clients: convertDecimalsToNumbers(clients),
        skip,
        take,
      });
    } catch (error) {
      logger.error('Get clients error:', error);
      res.status(500).json({ error: 'Failed to get clients' });
    }
  }

  async getClientById(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { id } = req.params;
      const client = await clientService.getClientWithTransactions(id, req.user.id);

      res.status(200).json({ client: convertDecimalsToNumbers(client) });
    } catch (error) {
      logger.error('Get client error:', error);
      if (error instanceof Error && error.message === 'Client not found') {
        res.status(404).json({ error: 'Client not found' });
      } else {
        res.status(500).json({ error: 'Failed to get client' });
      }
    }
  }

  async updateClient(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { id } = req.params;
      const { firstName, lastName, phone, email, address } = req.body;

      const client = await clientService.updateClient(id, req.user.id, {
        firstName,
        lastName,
        phone,
        email,
        address,
      });

      logger.info(`Client updated: ${id}`);
      res.status(200).json({
        message: 'Client updated successfully',
        client: convertDecimalsToNumbers(client),
      });
    } catch (error) {
      logger.error('Update client error:', error);
      if (error instanceof Error && error.message === 'Client not found') {
        res.status(404).json({ error: 'Client not found' });
      } else {
        res.status(500).json({ error: 'Failed to update client' });
      }
    }
  }

  async deleteClient(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { id } = req.params;
      await clientService.deleteClient(id, req.user.id);

      logger.info(`Client deleted: ${id}`);
      res.status(200).json({ message: 'Client deleted successfully' });
    } catch (error) {
      logger.error('Delete client error:', error);
      if (error instanceof Error && error.message === 'Client not found') {
        res.status(404).json({ error: 'Client not found' });
      } else {
        res.status(500).json({ error: 'Failed to delete client' });
      }
    }
  }

  async searchClients(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { q } = req.query;

      if (!q || typeof q !== 'string') {
        res.status(400).json({ error: 'Search query is required' });
        return;
      }

      const clients = await clientService.searchClients(req.user.id, q);
      res.status(200).json({ clients });
    } catch (error) {
      logger.error('Search clients error:', error);
      res.status(500).json({ error: 'Failed to search clients' });
    }
  }

  async setClientActiveStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { id } = req.params;
      const { isActive } = req.body;

      if (typeof isActive !== 'boolean') {
        res.status(400).json({ error: 'isActive must be a boolean' });
        return;
      }

      const client = await clientService.setClientActiveStatus(id, req.user.id, isActive);
      
      logger.info(`Client ${id} status changed to ${isActive ? 'active' : 'inactive'} by user ${req.user.id}`);
      res.status(200).json({
        message: `Client ${isActive ? 'activated' : 'deactivated'} successfully`,
        client,
      });
    } catch (error) {
      logger.error('Set client status error:', error);
      res.status(500).json({ error: 'Failed to update client status' });
    }
  }
}

export default new ClientController();
