import { Request, Response } from 'express';
import { User } from '../models/User';

export const getProfile = async (req: Request, res: Response): Promise<void> => {
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
    res.status(500).json({ message: 'Profil alınırken hata oluştu' });
  }
};

export const updateProfile = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;

    const allowedFields = [
      'name', 'username', 'phoneNumber', 'birthDate',
      'gender', 'currency', 'timezone',
    ];

    const user = await User.findById(userId);
    if (!user) {
      res.status(404).json({ message: 'Kullanıcı bulunamadı' });
      return;
    }

    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        (user as any)[field] = req.body[field];
      }
    });

    user.stats.lastActiveDate = new Date();
    await user.save();

    res.json(user);
  } catch (error: any) {
    if (error.code === 11000) {
      res.status(400).json({ message: 'Bu kullanıcı adı zaten kullanılıyor' });
      return;
    }
    res.status(500).json({ message: 'Profil güncellenirken hata oluştu' });
  }
};

export const updatePreferences = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;
    const { notifications, darkMode, language, monthlyBudget, weeklyBudget } = req.body;

    const update: Record<string, unknown> = {};
    if (notifications !== undefined) update['preferences.notifications'] = notifications;
    if (darkMode !== undefined) update['preferences.darkMode'] = darkMode;
    if (language !== undefined) update['preferences.language'] = language;
    if (monthlyBudget !== undefined) update['preferences.monthlyBudget'] = monthlyBudget;
    if (weeklyBudget !== undefined) update['preferences.weeklyBudget'] = weeklyBudget;

    const user = await User.findByIdAndUpdate(userId, { $set: update }, { new: true });

    if (!user) {
      res.status(404).json({ message: 'Kullanıcı bulunamadı' });
      return;
    }

    res.json({ preferences: user.preferences });
  } catch (error) {
    res.status(500).json({ message: 'Tercihler güncellenirken hata oluştu' });
  }
};

export const changePassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user._id;

    const user = await User.findById(userId).select('+password');
    if (!user) {
      res.status(404).json({ message: 'Kullanıcı bulunamadı' });
      return;
    }

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      res.status(400).json({ message: 'Mevcut şifre hatalı' });
      return;
    }

    user.password = newPassword;
    await user.save();

    res.json({ message: 'Şifre başarıyla güncellendi' });
  } catch (error) {
    res.status(500).json({ message: 'Şifre güncellenirken hata oluştu' });
  }
};

export const deleteAccount = async (req: Request, res: Response): Promise<void> => {
  try {
    const { password } = req.body;
    const userId = req.user._id;

    const user = await User.findById(userId).select('+password');
    if (!user) {
      res.status(404).json({ message: 'Kullanıcı bulunamadı' });
      return;
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      res.status(400).json({ message: 'Şifre hatalı' });
      return;
    }

    user.isActive = false;
    await user.save();

    res.json({ message: 'Hesap başarıyla devre dışı bırakıldı' });
  } catch (error) {
    res.status(500).json({ message: 'Hesap silinirken hata oluştu' });
  }
};
