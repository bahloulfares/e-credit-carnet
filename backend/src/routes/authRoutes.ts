import { Router, Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import rateLimit from 'express-rate-limit';
import authController from '../controllers/authController';
import { authMiddleware } from '../middleware/auth';

const router = Router();

const authLimiter = rateLimit({
	windowMs: 15 * 60 * 1000,
	max: 20,
	standardHeaders: true,
	legacyHeaders: false,
	message: {
		error: 'Too many authentication attempts. Please try again later.',
	},
});

const registerValidation = [
	body('email').isEmail().withMessage('Invalid email format'),
	body('firstName').trim().isLength({ min: 2, max: 50 }).withMessage('First name is required'),
	body('lastName').trim().isLength({ min: 2, max: 50 }).withMessage('Last name is required'),
	body('password').isLength({ min: 8, max: 128 }).withMessage('Password must be at least 8 characters'),
];

const loginValidation = [
	body('email').isEmail().withMessage('Invalid email format'),
	body('password').isLength({ min: 1 }).withMessage('Password is required'),
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

// Public routes
router.post('/register', authLimiter, registerValidation, validateRequest, (req: Request, res: Response) =>
	authController.register(req, res));
router.post('/login', authLimiter, loginValidation, validateRequest, (req: Request, res: Response) =>
	authController.login(req, res));

// Protected routes
router.get('/profile', authMiddleware, (req, res) => authController.getProfile(req, res));
router.put('/profile', authMiddleware, (req, res) => authController.updateProfile(req, res));
router.post('/logout', authMiddleware, (req, res) => authController.logout(req, res));

export default router;
