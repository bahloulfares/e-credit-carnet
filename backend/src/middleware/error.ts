import { Request, Response, NextFunction } from 'express';
import logger from '../utils/logger';
import { ApiError } from '../utils/errors';

export const errorMiddleware = (
  error: Error | ApiError,
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  logger.error('Error:', error);

  if (error instanceof ApiError) {
    res.status(error.statusCode).json({
      error: error.message,
      statusCode: error.statusCode,
    });
    return;
  }

  res.status(500).json({
    error: 'Internal Server Error',
    statusCode: 500,
  });
};

export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>,
) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
