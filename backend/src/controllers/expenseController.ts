import { Request, Response } from 'express';
import { Types } from 'mongoose';
import { Expense } from '../models/Expense';
import { Group } from '../models/Group';

export const createExpense = async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      title,
      description,
      amount,
      currency,
      date,
      categoryId,
      category,
      localId,
      type,
      groupId,
      paidBy,
      splitBetween,
      splitAmounts,
      tags,
      isRecurring,
      recurringPattern,
    } = req.body;

    const userId = req.user._id;

    if (type === 'group' && !groupId) {
      res.status(400).json({ message: 'Grup harcaması için groupId gereklidir' });
      return;
    }

    if (type === 'group' && groupId) {
      const group = await Group.findById(groupId);
      if (!group || !group.isMember(userId)) {
        res.status(403).json({ message: 'Bu gruba erişim izniniz yok' });
        return;
      }
    }

    // localId ile var mı kontrol et (upsert mantığı)
    if (localId) {
      const existing = await Expense.findOne({ localId, userId });
      if (existing) {
        res.status(200).json(existing);
        return;
      }
    }

    const expense = new Expense({
      title,
      description,
      amount,
      currency: currency || 'TRY',
      date: date || new Date(),
      categoryId: categoryId || undefined,
      category,
      localId,
      type: type || 'personal',
      userId,
      groupId,
      paidBy: paidBy || userId,
      splitBetween,
      splitAmounts,
      tags,
      isRecurring,
      recurringPattern,
    });

    await expense.save();

    if (type === 'group' && groupId) {
      await Group.findByIdAndUpdate(groupId, {
        $inc: { 'stats.totalExpenses': 1, 'stats.totalAmount': amount },
        'stats.lastActivity': new Date(),
      });
    }

    res.status(201).json(expense);
  } catch (error) {
    res.status(500).json({ message: 'Harcama oluşturulurken hata oluştu' });
  }
};

export const getExpenses = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;
    const { type, groupId, categoryId, startDate, endDate, status, page = '1', limit = '20' } = req.query;

    const query: Record<string, unknown> = { userId, status: status || 'active' };

    if (type) query.type = type;
    if (groupId) query.groupId = groupId;
    if (categoryId) query.categoryId = categoryId;
    if (startDate && endDate) {
      query.date = {
        $gte: new Date(startDate as string),
        $lte: new Date(endDate as string),
      };
    }

    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);
    const skip = (pageNum - 1) * limitNum;

    const [expenses, total] = await Promise.all([
      Expense.find(query)
        .sort({ date: -1 })
        .skip(skip)
        .limit(limitNum)
        .populate('categoryId', 'name icon color')
        .populate('groupId', 'name'),
      Expense.countDocuments(query),
    ]);

    res.json({
      expenses,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Harcamalar alınırken hata oluştu' });
  }
};

export const getExpenseById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const expense = await Expense.findOne({ _id: id, userId })
      .populate('categoryId', 'name icon color')
      .populate('groupId', 'name')
      .populate('paidBy', 'name email');

    if (!expense) {
      res.status(404).json({ message: 'Harcama bulunamadı' });
      return;
    }

    res.json(expense);
  } catch (error) {
    res.status(500).json({ message: 'Harcama alınırken hata oluştu' });
  }
};

export const updateExpense = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const expense = await Expense.findOne({ _id: id, userId, status: 'active' });
    if (!expense) {
      res.status(404).json({ message: 'Harcama bulunamadı' });
      return;
    }

    const allowedFields = [
      'title', 'description', 'amount', 'currency', 'date',
      'categoryId', 'category', 'tags', 'isRecurring', 'recurringPattern',
      'splitBetween', 'splitAmounts',
    ];

    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        (expense as any)[field] = req.body[field];
      }
    });

    await expense.save();
    res.json(expense);
  } catch (error) {
    res.status(500).json({ message: 'Harcama güncellenirken hata oluştu' });
  }
};

export const deleteExpense = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const expense = await Expense.findOne({ _id: id, userId, status: 'active' });
    if (!expense) {
      res.status(404).json({ message: 'Harcama bulunamadı' });
      return;
    }

    // Soft delete
    expense.status = 'deleted';
    await expense.save();

    // Grup istatistiklerini güncelle
    if (expense.type === 'group' && expense.groupId) {
      await Group.findByIdAndUpdate(expense.groupId, {
        $inc: { 'stats.totalExpenses': -1, 'stats.totalAmount': -expense.amount },
      });
    }

    res.json({ message: 'Harcama başarıyla silindi' });
  } catch (error) {
    res.status(500).json({ message: 'Harcama silinirken hata oluştu' });
  }
};

export const updateExpenseByLocalId = async (req: Request, res: Response): Promise<void> => {
  try {
    const { localId } = req.params;
    const userId = req.user._id;

    const expense = await Expense.findOne({ localId, userId, status: 'active' });
    if (!expense) {
      res.status(404).json({ message: 'Harcama bulunamadı' });
      return;
    }

    const allowedFields = ['title', 'description', 'amount', 'currency', 'date', 'categoryId', 'category', 'tags'];
    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        (expense as any)[field] = req.body[field];
      }
    });

    await expense.save();
    res.json(expense);
  } catch (error) {
    res.status(500).json({ message: 'Harcama güncellenirken hata oluştu' });
  }
};

export const deleteExpenseByLocalId = async (req: Request, res: Response): Promise<void> => {
  try {
    const { localId } = req.params;
    const userId = req.user._id;

    const expense = await Expense.findOne({ localId, userId, status: 'active' });
    if (!expense) {
      res.status(404).json({ message: 'Harcama bulunamadı' });
      return;
    }

    expense.status = 'deleted';
    await expense.save();
    res.json({ message: 'Harcama başarıyla silindi' });
  } catch (error) {
    res.status(500).json({ message: 'Harcama silinirken hata oluştu' });
  }
};

export const getExpenseStats = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;
    const { startDate, endDate } = req.query;

    const matchQuery: Record<string, unknown> = {
      userId: new Types.ObjectId(String(userId)),
      status: 'active',
    };

    if (startDate && endDate) {
      matchQuery.date = {
        $gte: new Date(startDate as string),
        $lte: new Date(endDate as string),
      };
    }

    const [byCategory, summary] = await Promise.all([
      Expense.aggregate([
        { $match: matchQuery },
        {
          $group: {
            _id: { $ifNull: ['$category', 'Diğer'] },
            totalAmount: { $sum: '$amount' },
            count: { $sum: 1 },
          },
        },
        { $sort: { totalAmount: -1 } },
      ]),
      Expense.aggregate([
        { $match: matchQuery },
        {
          $group: {
            _id: null,
            totalAmount: { $sum: '$amount' },
            count: { $sum: 1 },
            avgAmount: { $avg: '$amount' },
          },
        },
      ]),
    ]);

    res.json({
      byCategory,
      summary: summary[0] || { totalAmount: 0, count: 0, avgAmount: 0 },
    });
  } catch (error) {
    res.status(500).json({ message: 'İstatistikler alınırken hata oluştu' });
  }
};
