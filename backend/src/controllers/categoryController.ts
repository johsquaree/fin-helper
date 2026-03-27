import { Request, Response } from 'express';
import { Category } from '../models/Category';
import { User } from '../models/User';

export const getCategories = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;
    const { type } = req.query;

    const query: Record<string, unknown> = {
      $or: [{ userId }, { isDefault: true }],
      isActive: true,
    };

    if (type) query.type = type;

    const categories = await Category.find(query)
      .populate('subcategories', 'name icon color')
      .sort({ isDefault: 1, name: 1 });

    res.json(categories);
  } catch (error) {
    res.status(500).json({ message: 'Kategoriler alınırken hata oluştu' });
  }
};

export const getCategoryById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const category = await Category.findOne({
      _id: id,
      $or: [{ userId }, { isDefault: true }],
      isActive: true,
    }).populate('subcategories', 'name icon color');

    if (!category) {
      res.status(404).json({ message: 'Kategori bulunamadı' });
      return;
    }

    res.json(category);
  } catch (error) {
    res.status(500).json({ message: 'Kategori alınırken hata oluştu' });
  }
};

export const createCategory = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, description, icon, color, type, parentCategory } = req.body;
    const userId = req.user._id;

    const existing = await Category.findOne({ name, userId, isActive: true });
    if (existing) {
      res.status(400).json({ message: 'Bu isimde bir kategori zaten mevcut' });
      return;
    }

    const category = new Category({
      name,
      description,
      icon: icon || '📦',
      color: color || '#3B82F6',
      type,
      userId,
      parentCategory,
      isDefault: false,
    });

    await category.save();

    // Alt kategori ise parent'a ekle
    if (parentCategory) {
      await Category.findByIdAndUpdate(parentCategory, {
        $addToSet: { subcategories: category._id },
      });
    }

    // Kullanıcıya ata
    await User.findByIdAndUpdate(userId, {
      $addToSet: { categories: category._id },
    });

    res.status(201).json(category);
  } catch (error) {
    res.status(500).json({ message: 'Kategori oluşturulurken hata oluştu' });
  }
};

export const updateCategory = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const category = await Category.findOne({ _id: id, userId, isActive: true });
    if (!category) {
      res.status(404).json({ message: 'Kategori bulunamadı veya düzenleme izniniz yok' });
      return;
    }

    const allowedFields = ['name', 'description', 'icon', 'color'];
    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        (category as any)[field] = req.body[field];
      }
    });

    await category.save();
    res.json(category);
  } catch (error) {
    res.status(500).json({ message: 'Kategori güncellenirken hata oluştu' });
  }
};

export const deleteCategory = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const category = await Category.findOne({ _id: id, userId, isActive: true });
    if (!category) {
      res.status(404).json({ message: 'Kategori bulunamadı veya silme izniniz yok' });
      return;
    }

    category.isActive = false;
    await category.save();

    await User.findByIdAndUpdate(userId, { $pull: { categories: id } });

    res.json({ message: 'Kategori başarıyla silindi' });
  } catch (error) {
    res.status(500).json({ message: 'Kategori silinirken hata oluştu' });
  }
};
