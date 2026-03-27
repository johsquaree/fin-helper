import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

import { config } from './config/config';
import { generalLimiter } from './middlewares/rateLimitMiddleware';
import { notFound, errorHandler } from './middlewares/errorMiddleware';

import authRoutes from './routes/authRoutes';
import expenseRoutes from './routes/expenseRoutes';
import groupRoutes from './routes/groupRoutes';
import categoryRoutes from './routes/categoryRoutes';
import budgetRoutes from './routes/budgetRoutes';
import notificationRoutes from './routes/notificationRoutes';
import userRoutes from './routes/userRoutes';

const app = express();

// Güvenlik başlıkları
app.use(helmet());

// CORS - sadece izin verilen origin'lere
app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || config.allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('CORS politikası tarafından engellendi'));
      }
    },
    credentials: true,
  })
);

// Body parser - boyut limiti
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Genel rate limiting
app.use('/api', generalLimiter);

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Route'lar
app.use('/api/auth', authRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/users', userRoutes);

// 404 handler
app.use(notFound);

// Global error handler
app.use(errorHandler);

export default app;
