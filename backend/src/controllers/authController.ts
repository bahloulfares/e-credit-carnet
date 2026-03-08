import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import authService from '../services/authService';
import { generateToken } from '../utils/jwt';
import logger from '../utils/logger';

export class AuthController {
  async register(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { email, firstName, lastName, password, shopName, phone } = req.body;

      if (!email || !firstName || !lastName || !password) {
        res.status(400).json({ error: 'Missing required fields' });
        return;
      }

      const user = await authService.register({
        email,
        firstName,
        lastName,
        password,
        shopName,
        phone,
      });

      const token = generateToken({
        id: user.id,
        email: user.email,
        role: user.role,
      });

      logger.info(`New user registered: ${email}`);
      res.status(201).json({
        message: 'User registered successfully',
        token,
        user,
      });
    } catch (error) {
      logger.error('Registration error:', error);
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Registration failed' });
      }
    }
  }

  async login(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        res.status(400).json({ error: 'Email and password are required' });
        return;
      }

      const user = await authService.login(email, password);

      const token = generateToken({
        id: user.id,
        email: user.email,
        role: user.role,
      });

      logger.info(`User logged in: ${email}`);
      res.status(200).json({
        message: 'Login successful',
        token,
        user,
      });
    } catch (error) {
      logger.error('Login error:', error);
      if (error instanceof Error) {
        res.status(401).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Login failed' });
      }
    }
  }

  async getProfile(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const user = await authService.getUserById(req.user.id);

      if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
      }

      res.status(200).json({ user });
    } catch (error) {
      logger.error('Get profile error:', error);
      res.status(500).json({ error: 'Failed to get profile' });
    }
  }

  async updateProfile(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { firstName, lastName, shopName, shopAddress, shopPhone, phone } = req.body;

      const user = await authService.updateUser(req.user.id, {
        firstName,
        lastName,
        shopName,
        shopAddress,
        shopPhone,
        phone,
      });

      logger.info(`User profile updated: ${user.email}`);
      res.status(200).json({
        message: 'Profile updated successfully',
        user,
      });
    } catch (error) {
      logger.error('Update profile error:', error);
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to update profile' });
      }
    }
  }

  async logout(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      logger.info(`User logged out: ${req.user.email}`);
      res.status(200).json({ message: 'Logged out successfully' });
    } catch (error) {
      logger.error('Logout error:', error);
      res.status(500).json({ error: 'Logout failed' });
    }
  }
}

export default new AuthController();
