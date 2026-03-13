import { Router, Request, Response, NextFunction } from 'express';
import { query, validationResult } from 'express-validator';
import transactionController from '../controllers/transactionController';
import { authMiddleware, epicierOrAdminMiddleware } from '../middleware/auth';
import { asyncHandler } from '../middleware/error';

const router = Router();

const transactionListValidation = [
	query('skip').optional().isInt({ min: 0 }).withMessage('skip must be >= 0'),
	query('take')
		.optional()
		.isInt({ min: 1, max: 100 })
		.withMessage('take must be between 1 and 100'),
	query('type')
		.optional()
		.isIn(['CREDIT', 'PAYMENT'])
		.withMessage('type must be CREDIT or PAYMENT'),
	query('isPaid')
		.optional()
		.isIn(['true', 'false'])
		.withMessage('isPaid must be true or false'),
	query('month')
		.optional()
		.isInt({ min: 1, max: 12 })
		.withMessage('month must be between 1 and 12'),
	query('year')
		.optional()
		.isInt({ min: 2000, max: 2100 })
		.withMessage('year must be between 2000 and 2100'),
];

const validateRequest = (req: Request, res: Response, next: NextFunction): void => {
	const errors = validationResult(req);

	if (!errors.isEmpty()) {
		res.status(400).json({
			error: 'Validation failed',
			details: errors.array(),
		});
		return;
	}

	next();
};

// All routes require authentication and business role (EPICIER or SUPER_ADMIN)
router.use(authMiddleware, epicierOrAdminMiddleware);

// Transaction operations
router.post('/', asyncHandler((req, res) => transactionController.createTransaction(req, res)));
router.get(
	'/',
	transactionListValidation,
	validateRequest,
	asyncHandler((req, res) => transactionController.getTransactions(req, res)),
);
router.get('/:id', asyncHandler((req, res) => transactionController.getTransactionById(req, res)));
router.put('/:id', asyncHandler((req, res) => transactionController.updateTransaction(req, res)));
router.delete('/:id', asyncHandler((req, res) => transactionController.deleteTransaction(req, res)));
// Mark as paid route removed - use createTransaction with type PAYMENT instead

export default router;
