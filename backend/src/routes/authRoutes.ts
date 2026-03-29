import { Router } from 'express';
import {
  register,
  login,
  refreshTokenHandler,
  logout,
  forgotPassword,
  resetPassword,
  verifyEmail,
  getMe,
} from '../controllers/authController';
import { auth } from '../middlewares/authMiddleware';
import { authLimiter, forgotPasswordLimiter } from '../middlewares/rateLimitMiddleware';
import {
  validateRegister,
  validateLogin,
  validateForgotPassword,
  validateResetPassword,
} from '../middlewares/validationMiddleware';

const router = Router();

router.post('/register', authLimiter, validateRegister, register);
router.post('/login', authLimiter, validateLogin, login);
router.post('/refresh-token', refreshTokenHandler);
router.post('/verify-email', verifyEmail);
router.post('/forgot-password', forgotPasswordLimiter, validateForgotPassword, forgotPassword);
router.post('/reset-password', validateResetPassword, resetPassword);

router.use(auth);
router.post('/logout', logout);
router.get('/me', getMe);

export default router;
