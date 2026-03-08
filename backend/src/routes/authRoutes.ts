import { Router } from 'express';
import authController from '../controllers/authController';
import { authMiddleware } from '../middleware/auth';

const router = Router();

// Public routes
router.post('/register', (req, res) => authController.register(req, res));
router.post('/login', (req, res) => authController.login(req, res));

// Protected routes
router.get('/profile', authMiddleware, (req, res) => authController.getProfile(req, res));
router.put('/profile', authMiddleware, (req, res) => authController.updateProfile(req, res));
router.post('/logout', authMiddleware, (req, res) => authController.logout(req, res));

export default router;
