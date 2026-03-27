import { Request, Response } from 'express';
import { Group } from '../models/Group';
import { User } from '../models/User';
import { Expense } from '../models/Expense';

export const createGroup = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, description, icon, color, memberIds, settings } = req.body;
    const createdBy = req.user._id;

    // Üye ID'lerini al ve kurucuyu ekle
    const uniqueMemberIds = [...new Set([...(memberIds || []), String(createdBy)])];

    const memberObjects = uniqueMemberIds.map((id) => ({
      userId: id,
      role: String(id) === String(createdBy) ? 'admin' : 'member',
      joinedAt: new Date(),
      isActive: true,
    }));

    const group = new Group({
      name,
      description,
      icon,
      color,
      members: memberObjects,
      createdBy,
      settings,
    });

    await group.save();

    await User.updateMany(
      { _id: { $in: uniqueMemberIds } },
      { $addToSet: { groups: group._id } }
    );

    const populated = await group.populate([
      { path: 'members.userId', select: 'name email profileImage' },
      { path: 'createdBy', select: 'name email profileImage' },
    ]);

    res.status(201).json(populated);
  } catch (error) {
    res.status(500).json({ message: 'Grup oluşturulurken hata oluştu' });
  }
};

export const getGroups = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user._id;

    const groups = await Group.find({
      'members.userId': userId,
      'members.isActive': true,
      status: 'active',
    })
      .populate('members.userId', 'name email profileImage')
      .populate('createdBy', 'name email profileImage')
      .sort({ 'stats.lastActivity': -1 });

    res.json(groups);
  } catch (error) {
    res.status(500).json({ message: 'Gruplar alınırken hata oluştu' });
  }
};

export const getGroupDetails = async (req: Request, res: Response): Promise<void> => {
  try {
    const { groupId } = req.params;
    const userId = req.user._id;

    const group = await Group.findOne({
      _id: groupId,
      'members.userId': userId,
      'members.isActive': true,
      status: 'active',
    })
      .populate('members.userId', 'name email profileImage')
      .populate('createdBy', 'name email profileImage');

    if (!group) {
      res.status(404).json({ message: 'Grup bulunamadı veya erişim izniniz yok' });
      return;
    }

    res.json(group);
  } catch (error) {
    res.status(500).json({ message: 'Grup detayları alınırken hata oluştu' });
  }
};

export const updateGroup = async (req: Request, res: Response): Promise<void> => {
  try {
    const { groupId } = req.params;
    const userId = req.user._id;

    const group = await Group.findOne({ _id: groupId, status: 'active' });
    if (!group || !group.isAdmin(userId)) {
      res.status(403).json({ message: 'Bu grubu düzenleme izniniz yok' });
      return;
    }

    const allowedFields = ['name', 'description', 'icon', 'color', 'settings', 'isPublic'];
    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        (group as any)[field] = req.body[field];
      }
    });

    await group.save();

    const populated = await group.populate([
      { path: 'members.userId', select: 'name email profileImage' },
      { path: 'createdBy', select: 'name email profileImage' },
    ]);

    res.json(populated);
  } catch (error) {
    res.status(500).json({ message: 'Grup güncellenirken hata oluştu' });
  }
};

export const deleteGroup = async (req: Request, res: Response): Promise<void> => {
  try {
    const { groupId } = req.params;
    const userId = req.user._id;

    const group = await Group.findOne({ _id: groupId, status: 'active' });
    if (!group || String(group.createdBy) !== String(userId)) {
      res.status(403).json({ message: 'Bu grubu silme izniniz yok' });
      return;
    }

    group.status = 'deleted';
    await group.save();

    // Kullanıcıların groups dizisinden kaldır
    const memberIds = group.members.map((m) => m.userId);
    await User.updateMany({ _id: { $in: memberIds } }, { $pull: { groups: group._id } });

    res.json({ message: 'Grup başarıyla silindi' });
  } catch (error) {
    res.status(500).json({ message: 'Grup silinirken hata oluştu' });
  }
};

export const addMemberToGroup = async (req: Request, res: Response): Promise<void> => {
  try {
    const { groupId } = req.params;
    const { memberId } = req.body;
    const userId = req.user._id;

    const group = await Group.findOne({ _id: groupId, status: 'active' });
    if (!group || !group.isMember(userId)) {
      res.status(404).json({ message: 'Grup bulunamadı veya erişim izniniz yok' });
      return;
    }

    if (!group.settings.allowMemberInvites && !group.isAdmin(userId)) {
      res.status(403).json({ message: 'Bu gruba üye ekleme izniniz yok' });
      return;
    }

    const targetUser = await User.findById(memberId);
    if (!targetUser) {
      res.status(404).json({ message: 'Kullanıcı bulunamadı' });
      return;
    }

    if (group.isMember(memberId)) {
      res.status(400).json({ message: 'Kullanıcı zaten grup üyesi' });
      return;
    }

    group.addMember(memberId);
    await group.save();

    await User.findByIdAndUpdate(memberId, { $addToSet: { groups: groupId } });

    res.json({ message: 'Üye başarıyla eklendi' });
  } catch (error) {
    res.status(500).json({ message: 'Üye eklenirken hata oluştu' });
  }
};

export const removeMemberFromGroup = async (req: Request, res: Response): Promise<void> => {
  try {
    const { groupId, memberId } = req.params;
    const userId = req.user._id;

    const group = await Group.findOne({ _id: groupId, status: 'active' });
    if (!group) {
      res.status(404).json({ message: 'Grup bulunamadı' });
      return;
    }

    // Admin üye çıkarabilir veya kullanıcı kendisi çıkabilir
    const isSelf = String(userId) === memberId;
    if (!isSelf && !group.isAdmin(userId)) {
      res.status(403).json({ message: 'Bu kullanıcıyı gruptan çıkarma izniniz yok' });
      return;
    }

    // Grubun yaratıcısı çıkarılamaz
    if (String(group.createdBy) === memberId) {
      res.status(400).json({ message: 'Grup kurucusu gruptan çıkarılamaz' });
      return;
    }

    group.removeMember(memberId);
    await group.save();

    await User.findByIdAndUpdate(memberId, { $pull: { groups: groupId } });

    res.json({ message: 'Üye başarıyla gruptan çıkarıldı' });
  } catch (error) {
    res.status(500).json({ message: 'Üye çıkarılırken hata oluştu' });
  }
};

export const updateMemberRole = async (req: Request, res: Response): Promise<void> => {
  try {
    const { groupId, memberId } = req.params;
    const { role } = req.body;
    const userId = req.user._id;

    if (!['admin', 'member'].includes(role)) {
      res.status(400).json({ message: 'Geçersiz rol. admin veya member olmalıdır' });
      return;
    }

    const group = await Group.findOne({ _id: groupId, status: 'active' });
    if (!group || !group.isAdmin(userId)) {
      res.status(403).json({ message: 'Rol değiştirme izniniz yok' });
      return;
    }

    const member = group.members.find(
      (m) => String(m.userId) === memberId && m.isActive
    );

    if (!member) {
      res.status(404).json({ message: 'Üye bulunamadı' });
      return;
    }

    member.role = role;
    await group.save();

    res.json({ message: 'Üye rolü güncellendi' });
  } catch (error) {
    res.status(500).json({ message: 'Rol güncellenirken hata oluştu' });
  }
};

export const joinGroupByInviteCode = async (req: Request, res: Response): Promise<void> => {
  try {
    const { inviteCode } = req.body;
    const userId = req.user._id;

    const group = await (Group as any).findByInviteCode(inviteCode);
    if (!group) {
      res.status(404).json({ message: 'Geçersiz davet kodu' });
      return;
    }

    if (group.isMember(userId)) {
      res.status(400).json({ message: 'Zaten bu grubun üyesisiniz' });
      return;
    }

    group.addMember(userId);
    await group.save();

    await User.findByIdAndUpdate(userId, { $addToSet: { groups: group._id } });

    res.json({ message: 'Gruba başarıyla katıldınız', group });
  } catch (error) {
    res.status(500).json({ message: 'Gruba katılırken hata oluştu' });
  }
};

export const getGroupExpenses = async (req: Request, res: Response): Promise<void> => {
  try {
    const { groupId } = req.params;
    const userId = req.user._id;
    const { page = '1', limit = '20' } = req.query;

    const group = await Group.findOne({ _id: groupId, status: 'active' });
    if (!group || !group.isMember(userId)) {
      res.status(403).json({ message: 'Bu gruba erişim izniniz yok' });
      return;
    }

    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);
    const skip = (pageNum - 1) * limitNum;

    const [expenses, total] = await Promise.all([
      Expense.find({ groupId, status: 'active' })
        .sort({ date: -1 })
        .skip(skip)
        .limit(limitNum)
        .populate('categoryId', 'name icon color')
        .populate('userId', 'name profileImage')
        .populate('paidBy', 'name profileImage'),
      Expense.countDocuments({ groupId, status: 'active' }),
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
    res.status(500).json({ message: 'Grup harcamaları alınırken hata oluştu' });
  }
};
