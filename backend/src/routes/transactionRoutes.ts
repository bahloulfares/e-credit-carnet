import { Router } from 'express';
import transactionController from '../controllers/transactionController';
import { authMiddleware, epicierOrAdminMiddleware } from '../middleware/auth';

const router = Router();

// All routes require authentication and business role (EPICIER or SUPER_ADMIN)
router.use(authMiddleware, epicierOrAdminMiddleware);

// Transaction operations
router.post('/', (req, res) => transactionController.createTransaction(req, res));
router.get('/', (req, res) => transactionController.getTransactions(req, res));
router.get('/:id', (req, res) => transactionController.getTransactionById(req, res));
router.put('/:id', (req, res) => transactionController.updateTransaction(req, res));
router.delete('/:id', (req, res) => transactionController.deleteTransaction(req, res));
// Mark as paid route removed - use createTransaction with type PAYMENT instead

export default router;
