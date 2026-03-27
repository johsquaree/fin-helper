import { Request, Response, NextFunction } from 'express';
import { config } from '../config/config';

export class AppError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

export const notFound = (req: Request, res: Response, next: NextFunction): void => {
  next(new AppError(`${req.originalUrl} bulunamadı`, 404));
};

export const errorHandler = (
  err: AppError | Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  const statusCode = (err as AppError).statusCode || 500;
  const isOperational = (err as AppError).isOperational || false;

  const response: Record<string, unknown> = {
    message: isOperational ? err.message : 'Bir hata oluştu',
  };

  if (config.nodeEnv === 'development') {
    response.stack = err.stack;
    if (!isOperational) {
      response.error = err.message;
    }
  }

  res.status(statusCode).json(response);
};
