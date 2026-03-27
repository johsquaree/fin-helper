import { Request, Response } from 'express';
import { Types } from 'mongoose';
import { Notification } from '../models/Notification';

export const getNotifications = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;
    const { unreadOnly, type, page = '1', limit = '20' } = req.query;

    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);

    const notifications = await (Notification as any).getUserNotifications(
      new Types.ObjectId(String(userId)),
      {
        limit: limitNum,
        skip: (pageNum - 1) * limitNum,
        unreadOnly: unreadOnly === 'true',
        type: type as string | undefined,
      }
    );

    const unreadCount = await (Notification as any).getUnreadCount(
      new Types.ObjectId(String(userId))
    );

    res.json({ notifications, unreadCount });
  } catch (error) {
    res.status(500).json({ message: 'Bildirimler alınırken hata oluştu' });
  }
};

export const markAsRead = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const notification = await Notification.findOne({ _id: id, userId });
    if (!notification) {
      res.status(404).json({ message: 'Bildirim bulunamadı' });
      return;
    }

    await notification.markAsRead();
    res.json({ message: 'Bildirim okundu olarak işaretlendi' });
  } catch (error) {
    res.status(500).json({ message: 'Bildirim güncellenirken hata oluştu' });
  }
};

export const markAllAsRead = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;
    await (Notification as any).markAllAsRead(new Types.ObjectId(String(userId)));
    res.json({ message: 'Tüm bildirimler okundu olarak işaretlendi' });
  } catch (error) {
    res.status(500).json({ message: 'Bildirimler güncellenirken hata oluştu' });
  }
};

export const deleteNotification = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const result = await Notification.deleteOne({ _id: id, userId });
    if (result.deletedCount === 0) {
      res.status(404).json({ message: 'Bildirim bulunamadı' });
      return;
    }

    res.json({ message: 'Bildirim silindi' });
  } catch (error) {
    res.status(500).json({ message: 'Bildirim silinirken hata oluştu' });
  }
};

export const getUnreadCount = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;
    const count = await (Notification as any).getUnreadCount(
      new Types.ObjectId(String(userId))
    );
    res.json({ count });
  } catch (error) {
    res.status(500).json({ message: 'Bildirim sayısı alınırken hata oluştu' });
  }
};
