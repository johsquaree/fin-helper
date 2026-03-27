import rateLimit from 'express-rate-limit';

export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100,
  message: { message: 'Çok fazla istek gönderildi, lütfen 15 dakika sonra tekrar deneyin' },
  standardHeaders: true,
  legacyHeaders: false,
});

export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 10,
  message: { message: 'Çok fazla giriş denemesi yapıldı, lütfen 15 dakika sonra tekrar deneyin' },
  standardHeaders: true,
  legacyHeaders: false,
});

export const forgotPasswordLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 saat
  max: 5,
  message: { message: 'Çok fazla şifre sıfırlama isteği gönderildi, lütfen 1 saat sonra tekrar deneyin' },
  standardHeaders: true,
  legacyHeaders: false,
});
