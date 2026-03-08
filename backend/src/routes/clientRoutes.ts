import { Router } from 'express';
import clientController from '../controllers/clientController';
import { authMiddleware, epicierOrAdminMiddleware } from '../middleware/auth';

const router = Router();

// All routes require authentication and business role (EPICIER or SUPER_ADMIN)
router.use(authMiddleware, epicierOrAdminMiddleware);

// CRUD operations
router.post('/', (req, res) => clientController.createClient(req, res));
router.get('/', (req, res) => clientController.getClients(req, res));
router.get('/search', (req, res) => clientController.searchClients(req, res));
router.get('/:id', (req, res) => clientController.getClientById(req, res));
router.put('/:id', (req, res) => clientController.updateClient(req, res));
router.delete('/:id', (req, res) => clientController.deleteClient(req, res));
router.patch('/:id/status', (req, res) => clientController.setClientActiveStatus(req, res));

export default router;
