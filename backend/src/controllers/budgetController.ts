import { Request, Response } from 'express';
import { Types } from 'mongoose';
import { Budget } from '../models/Budget';
import { User } from '../models/User';

export const getBudgets = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;
    const { status, type, page = '1', limit = '20' } = req.query;

    const query: Record<string, unknown> = { userId };
    if (status) query.status = status;
    if (type) query.type = type;

    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);
    const skip = (pageNum - 1) * limitNum;

    const [budgets, total] = await Promise.all([
      Budget.find(query)
        .populate('groupId', 'name icon')
        .populate('categoryId', 'name icon color')
        .sort({ startDate: -1 })
        .skip(skip)
        .limit(limitNum),
      Budget.countDocuments(query),
    ]);

    res.json({
      budgets,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Bütçeler alınırken hata oluştu' });
  }
};

export const getActiveBudgets = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;
    const budgets = await (Budget as any).getActiveBudgets(new Types.ObjectId(String(userId)));
    res.json(budgets);
  } catch (error) {
    res.status(500).json({ message: 'Aktif bütçeler alınırken hata oluştu' });
  }
};

export const getBudgetById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const budget = await Budget.findOne({ _id: id, userId })
      .populate('groupId', 'name icon')
      .populate('categoryId', 'name icon color');

    if (!budget) {
      res.status(404).json({ message: 'Bütçe bulunamadı' });
      return;
    }

    res.json(budget);
  } catch (error) {
    res.status(500).json({ message: 'Bütçe alınırken hata oluştu' });
  }
};

export const createBudget = async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      name,
      description,
      amount,
      currency,
      type,
      period,
      groupId,
      categoryId,
      startDate,
      endDate,
      settings,
    } = req.body;

    const userId = req.user._id;

    if (new Date(endDate) <= new Date(startDate)) {
      res.status(400).json({ message: 'Bitiş tarihi başlangıç tarihinden sonra olmalıdır' });
      return;
    }

    const budget = new Budget({
      name,
      description,
      amount,
      currency,
      type,
      period,
      userId,
      groupId,
      categoryId,
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      settings,
    });

    await budget.save();

    await User.findByIdAndUpdate(userId, { $addToSet: { budgets: budget._id } });

    res.status(201).json(budget);
  } catch (error) {
    res.status(500).json({ message: 'Bütçe oluşturulurken hata oluştu' });
  }
};

export const updateBudget = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const budget = await Budget.findOne({ _id: id, userId });
    if (!budget) {
      res.status(404).json({ message: 'Bütçe bulunamadı' });
      return;
    }

    const allowedFields = ['name', 'description', 'amount', 'settings', 'endDate'];
    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        (budget as any)[field] = req.body[field];
      }
    });

    await budget.save();
    res.json(budget);
  } catch (error) {
    res.status(500).json({ message: 'Bütçe güncellenirken hata oluştu' });
  }
};

export const deleteBudget = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const budget = await Budget.findOne({ _id: id, userId });
    if (!budget) {
      res.status(404).json({ message: 'Bütçe bulunamadı' });
      return;
    }

    budget.status = 'cancelled';
    await budget.save();

    await User.findByIdAndUpdate(userId, { $pull: { budgets: id } });

    res.json({ message: 'Bütçe başarıyla silindi' });
  } catch (error) {
    res.status(500).json({ message: 'Bütçe silinirken hata oluştu' });
  }
};
