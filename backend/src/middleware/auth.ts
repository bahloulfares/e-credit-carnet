import { Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';
import { verifyToken } from '../utils/jwt';
import logger from '../utils/logger';

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
  };
}

const prisma = new PrismaClient();

const hasAnyRole = (userRole: string | undefined, allowedRoles: string[]): boolean => {
  if (!userRole) {
    return false;
  }
  return allowedRoles.includes(userRole);
};

export const authMiddleware = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      res.status(401).json({ error: 'No token provided' });
      return;
    }

    const decoded = verifyToken(token);

    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      select: {
        id: true,
        email: true,
        role: true,
        isActive: true,
      },
    });

    if (!user) {
      res.status(401).json({ error: 'Invalid user account' });
      return;
    }

    if (!user.isActive) {
      res.status(403).json({ error: 'Account is deactivated' });
      return;
    }

    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
    };
    next();
  } catch (error) {
    logger.error('Authentication error:', error);
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

export const adminMiddleware = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): void => {
  if (!hasAnyRole(req.user?.role, ['SUPER_ADMIN'])) {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  next();
};

export const epicierMiddleware = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): void => {
  if (!hasAnyRole(req.user?.role, ['EPICIER'])) {
    res.status(403).json({ error: 'Epicier access required' });
    return;
  }
  next();
};

export const epicierOrAdminMiddleware = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): void => {
  if (!hasAnyRole(req.user?.role, ['EPICIER', 'SUPER_ADMIN'])) {
    res.status(403).json({ error: 'Epicier or admin access required' });
    return;
  }
  next();
};
