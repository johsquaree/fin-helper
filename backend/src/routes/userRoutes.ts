import { Router } from 'express';
import {
  getProfile,
  updateProfile,
  updatePreferences,
  changePassword,
  deleteAccount,
} from '../controllers/userController';
import { auth } from '../middlewares/authMiddleware';
import { body } from 'express-validator';
import { validate } from '../middlewares/validationMiddleware';

const router = Router();

router.use(auth);

router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.put('/preferences', updatePreferences);

router.put(
  '/change-password',
  [
    body('currentPassword').notEmpty().withMessage('Mevcut şifre gereklidir'),
    body('newPassword')
      .isLength({ min: 8 })
      .withMessage('Yeni şifre en az 8 karakter olmalıdır')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      .withMessage('Şifre en az bir küçük harf, büyük harf ve rakam içermelidir'),
    validate,
  ],
  changePassword
);

router.delete(
  '/account',
  [body('password').notEmpty().withMessage('Şifre gereklidir'), validate],
  deleteAccount
);

export default router;
