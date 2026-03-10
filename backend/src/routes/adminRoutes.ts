import { Router } from 'express';
import adminController from '../controllers/adminController';
import { authMiddleware, adminMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware, adminMiddleware);

router.get('/stats', (req, res) => adminController.getGlobalStats(req, res));
router.get('/epiciers', (req, res) => adminController.getEpiciers(req, res));
router.post('/epiciers', (req, res) => adminController.createEpicier(req, res));
router.get('/epiciers/:id', (req, res) => adminController.getEpicierById(req, res));
router.patch('/epiciers/:id', (req, res) => adminController.updateEpicier(req, res));
router.get('/epiciers/:id/clients', (req, res) =>
  adminController.getEpicierClients(req, res),
);
router.patch('/epiciers/:id/status', (req, res) =>
  adminController.updateEpicierStatus(req, res),
);
router.post('/epiciers/:id/reset-password', (req, res) =>
  adminController.resetEpicierPassword(req, res),
);

export default router;
