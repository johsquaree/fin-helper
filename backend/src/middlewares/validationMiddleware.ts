import { Request, Response, NextFunction } from 'express';
import { body, param, query, validationResult } from 'express-validator';

export const validate = (req: Request, res: Response, next: NextFunction): void => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({ message: 'Doğrulama hatası', errors: errors.array() });
    return;
  }
  next();
};

// Auth validasyonları
export const validateRegister = [
  body('email').isEmail().normalizeEmail().withMessage('Geçerli bir e-posta adresi girin'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Şifre en az 8 karakter olmalıdır')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Şifre en az bir küçük harf, büyük harf ve rakam içermelidir'),
  body('name')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('İsim 2-50 karakter arasında olmalıdır'),
  validate,
];

export const validateLogin = [
  body('email').isEmail().normalizeEmail().withMessage('Geçerli bir e-posta adresi girin'),
  body('password').notEmpty().withMessage('Şifre gereklidir'),
  validate,
];

export const validateForgotPassword = [
  body('email').isEmail().normalizeEmail().withMessage('Geçerli bir e-posta adresi girin'),
  validate,
];

export const validateResetPassword = [
  body('token').notEmpty().withMessage('Token gereklidir'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Şifre en az 8 karakter olmalıdır')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Şifre en az bir küçük harf, büyük harf ve rakam içermelidir'),
  validate,
];

// Expense validasyonları
export const validateCreateExpense = [
  body('title').trim().isLength({ min: 1, max: 100 }).withMessage('Başlık 1-100 karakter arasında olmalıdır'),
  body('amount')
    .isFloat({ min: 0.01, max: 999999999.99 })
    .withMessage('Miktar 0.01 ile 999999999.99 arasında olmalıdır'),
  body('categoryId').isMongoId().withMessage('Geçerli bir kategori ID gereklidir'),
  body('type').isIn(['personal', 'group']).withMessage('Tip personal veya group olmalıdır'),
  body('currency').optional().isIn(['TRY', 'USD', 'EUR', 'GBP']).withMessage('Geçersiz para birimi'),
  body('date').optional().isISO8601().withMessage('Geçerli bir tarih girin'),
  body('groupId').optional().isMongoId().withMessage('Geçerli bir grup ID girin'),
  validate,
];

export const validateUpdateExpense = [
  param('id').isMongoId().withMessage('Geçerli bir harcama ID gereklidir'),
  body('title').optional().trim().isLength({ min: 1, max: 100 }).withMessage('Başlık 1-100 karakter arasında olmalıdır'),
  body('amount').optional().isFloat({ min: 0.01 }).withMessage('Geçerli bir miktar girin'),
  body('categoryId').optional().isMongoId().withMessage('Geçerli bir kategori ID girin'),
  body('currency').optional().isIn(['TRY', 'USD', 'EUR', 'GBP']).withMessage('Geçersiz para birimi'),
  validate,
];

// Group validasyonları
export const validateCreateGroup = [
  body('name').trim().isLength({ min: 1, max: 50 }).withMessage('Grup adı 1-50 karakter arasında olmalıdır'),
  body('description').optional().trim().isLength({ max: 200 }).withMessage('Açıklama en fazla 200 karakter olabilir'),
  body('memberIds').optional().isArray().withMessage('memberIds dizi olmalıdır'),
  body('memberIds.*').optional().isMongoId().withMessage('Geçerli kullanıcı ID girin'),
  validate,
];

export const validateUpdateGroup = [
  param('groupId').isMongoId().withMessage('Geçerli bir grup ID gereklidir'),
  body('name').optional().trim().isLength({ min: 1, max: 50 }).withMessage('Grup adı 1-50 karakter arasında olmalıdır'),
  body('description').optional().trim().isLength({ max: 200 }).withMessage('Açıklama en fazla 200 karakter olabilir'),
  validate,
];

// Category validasyonları
export const validateCreateCategory = [
  body('name').trim().isLength({ min: 1, max: 50 }).withMessage('Kategori adı 1-50 karakter arasında olmalıdır'),
  body('type').isIn(['expense', 'income']).withMessage('Tip expense veya income olmalıdır'),
  body('icon').optional().trim().isLength({ min: 1, max: 10 }).withMessage('Geçerli bir icon girin'),
  body('color')
    .optional()
    .matches(/^#[0-9A-F]{6}$/i)
    .withMessage('Renk hex formatında olmalıdır (örn: #FF5733)'),
  validate,
];

// Budget validasyonları
export const validateCreateBudget = [
  body('name').trim().isLength({ min: 1, max: 100 }).withMessage('Bütçe adı 1-100 karakter arasında olmalıdır'),
  body('amount').isFloat({ min: 0.01 }).withMessage('Geçerli bir miktar girin'),
  body('type').isIn(['personal', 'group', 'category']).withMessage('Geçersiz bütçe tipi'),
  body('period').isIn(['daily', 'weekly', 'monthly', 'yearly']).withMessage('Geçersiz periyot'),
  body('startDate').isISO8601().withMessage('Geçerli bir başlangıç tarihi girin'),
  body('endDate').isISO8601().withMessage('Geçerli bir bitiş tarihi girin'),
  validate,
];

// Pagination validasyonu
export const validatePagination = [
  query('page').optional().isInt({ min: 1 }).withMessage('Sayfa numarası 1 veya daha büyük olmalıdır'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit 1-100 arasında olmalıdır'),
  validate,
];
