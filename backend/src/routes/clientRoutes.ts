import { Router } from 'express';
import { query, validationResult } from 'express-validator';
import clientController from '../controllers/clientController';
import { authMiddleware, epicierOrAdminMiddleware } from '../middleware/auth';
import { asyncHandler } from '../middleware/error';

const router = Router();

const listClientsValidation = [
	query('skip').optional().isInt({ min: 0 }).withMessage('skip must be >= 0'),
	query('take')
		.optional()
		.isInt({ min: 1, max: 100 })
		.withMessage('take must be between 1 and 100'),
];

const searchClientsValidation = [
	query('q')
		.isString()
		.trim()
		.isLength({ min: 1, max: 100 })
		.withMessage('q is required and must be between 1 and 100 characters'),
];

const validateRequest = (req: any, res: any, next: any): void => {
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

// CRUD operations
router.post('/', asyncHandler((req, res) => clientController.createClient(req, res)));
router.get(
	'/',
	listClientsValidation,
	validateRequest,
	asyncHandler((req, res) => clientController.getClients(req, res)),
);
router.get(
	'/search',
	searchClientsValidation,
	validateRequest,
	asyncHandler((req, res) => clientController.searchClients(req, res)),
);
router.get('/:id', asyncHandler((req, res) => clientController.getClientById(req, res)));
router.put('/:id', asyncHandler((req, res) => clientController.updateClient(req, res)));
router.delete('/:id', asyncHandler((req, res) => clientController.deleteClient(req, res)));
router.patch('/:id/status', asyncHandler((req, res) => clientController.setClientActiveStatus(req, res)));

export default router;
