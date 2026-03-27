import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { User } from '../models/User';
import { config } from '../config/config';

const generateTokens = (userId: string) => {
  const accessToken = jwt.sign({ userId }, config.jwtSecret, { expiresIn: '15m' });
  const refreshToken = jwt.sign({ userId }, config.jwtRefreshSecret, { expiresIn: '7d' });
  return { accessToken, refreshToken };
};

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password, name } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(400).json({ message: 'Bu e-posta adresi zaten kullanılıyor' });
      return;
    }

    const emailVerificationToken = crypto.randomBytes(32).toString('hex');
    const user = new User({
      email,
      password,
      name,
      emailVerificationToken: crypto.createHash('sha256').update(emailVerificationToken).digest('hex'),
    });
    await user.save();

    const { accessToken, refreshToken } = generateTokens(String(user._id));

    res.status(201).json({
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        isEmailVerified: user.isEmailVerified,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Kullanıcı oluşturulurken hata oluştu' });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      res.status(401).json({ message: 'E-posta veya şifre hatalı' });
      return;
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      res.status(401).json({ message: 'E-posta veya şifre hatalı' });
      return;
    }

    user.lastLogin = new Date();
    user.stats.lastActiveDate = new Date();
    await user.save();

    const { accessToken, refreshToken } = generateTokens(String(user._id));

    res.json({
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        isEmailVerified: user.isEmailVerified,
        currency: user.currency,
        preferences: user.preferences,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Giriş yapılırken hata oluştu' });
  }
};

export const refreshTokenHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const { refreshToken: token } = req.body;
    if (!token) {
      res.status(401).json({ message: 'Refresh token gerekli' });
      return;
    }

    const decoded = jwt.verify(token, config.jwtRefreshSecret) as { userId: string };
    const user = await User.findById(decoded.userId);
    if (!user || !user.isActive) {
      res.status(401).json({ message: 'Geçersiz token' });
      return;
    }

    const { accessToken, refreshToken: newRefreshToken } = generateTokens(decoded.userId);
    res.json({ accessToken, refreshToken: newRefreshToken });
  } catch (error) {
    res.status(401).json({ message: 'Geçersiz veya süresi dolmuş refresh token' });
  }
};

export const logout = async (_req: Request, res: Response): Promise<void> => {
  res.json({ message: 'Başarıyla çıkış yapıldı' });
};

export const forgotPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      // Güvenlik için kullanıcı bulunamasa da aynı mesajı döndür
      res.json({ message: 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi' });
      return;
    }

    const resetToken = user.generatePasswordResetToken();
    await user.save({ validateBeforeSave: false });

    // TODO: E-posta servisi entegre edildiğinde nodemailer eklenecek
    const responseData: Record<string, string> = {
      message: 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi',
    };
    if (config.nodeEnv === 'development') {
      responseData.resetToken = resetToken;
    }

    res.json(responseData);
  } catch (error) {
    res.status(500).json({ message: 'Şifre sıfırlama isteği oluşturulurken hata oluştu' });
  }
};

export const resetPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { token, password } = req.body;

    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
    const user = await User.findOne({
      passwordResetToken: hashedToken,
      passwordResetExpires: { $gt: Date.now() },
    }).select('+passwordResetToken +passwordResetExpires');

    if (!user) {
      res.status(400).json({ message: 'Geçersiz veya süresi dolmuş token' });
      return;
    }

    user.password = password;
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    await user.save();

    const { accessToken, refreshToken } = generateTokens(String(user._id));
    res.json({ message: 'Şifre başarıyla sıfırlandı', accessToken, refreshToken });
  } catch (error) {
    res.status(500).json({ message: 'Şifre sıfırlanırken hata oluştu' });
  }
};

export const getMe = async (req: Request, res: Response): Promise<void> => {
  try {
    const user = await User.findById(req.user._id)
      .populate('categories', 'name icon color type')
      .populate('budgets', 'name amount period status');

    if (!user) {
      res.status(404).json({ message: 'Kullanıcı bulunamadı' });
      return;
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Kullanıcı bilgileri alınırken hata oluştu' });
  }
};
