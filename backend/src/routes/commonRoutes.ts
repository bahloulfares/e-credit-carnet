import { Router } from 'express';
import dashboardController from '../controllers/dashboardController';
import syncController from '../controllers/syncController';
import { authMiddleware, epicierOrAdminMiddleware } from '../middleware/auth';

const router = Router();

// Dashboard stats
router.get('/dashboard/stats', authMiddleware, epicierOrAdminMiddleware, (req, res) =>
  dashboardController.getStats(req, res),
);
router.get('/dashboard/sync-status', authMiddleware, epicierOrAdminMiddleware, (req, res) =>
  dashboardController.getSyncStatus(req, res),
);

// Sync endpoint
router.post('/sync', authMiddleware, (req, res) => syncController.sync(req, res));

export default router;
