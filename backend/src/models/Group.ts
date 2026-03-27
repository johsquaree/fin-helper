import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IGroup extends Document {
  // Temel bilgiler
  name: string;
  description?: string;
  icon: string;
  color: string;
  
  // Üyeler
  members: {
    userId: Types.ObjectId;
    role: 'admin' | 'member';
    joinedAt: Date;
    isActive: boolean;
  }[];
  createdBy: Types.ObjectId;
  
  // Ayarlar
  settings: {
    allowMemberInvites: boolean;
    requireApprovalForExpenses: boolean;
    defaultCurrency: string;
    splitMethod: 'equal' | 'percentage' | 'custom';
    notifications: {
      newExpense: boolean;
      newMember: boolean;
      expenseReminder: boolean;
    };
  };
  
  // İstatistikler
  stats: {
    totalExpenses: number;
    totalAmount: number;
    memberCount: number;
    lastActivity: Date;
  };
  
  // Durum
  status: 'active' | 'archived' | 'deleted';
  isPublic: boolean;
  inviteCode?: string;
  
  // Sistem alanları
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;

  // Instance metodları
  generateInviteCode(): string;
  addMember(userId: Types.ObjectId | string, role?: 'admin' | 'member'): any;
  removeMember(userId: Types.ObjectId | string): boolean;
  isMember(userId: Types.ObjectId | string): boolean;
  isAdmin(userId: Types.ObjectId | string): boolean;
  updateStats(): Promise<void>;

  // Virtuals
  activeMembers: { userId: Types.ObjectId; role: 'admin' | 'member'; joinedAt: Date; isActive: boolean }[];
  adminMembers: { userId: Types.ObjectId; role: 'admin' | 'member'; joinedAt: Date; isActive: boolean }[];
}

const groupSchema = new Schema<IGroup>(
  {
    // Temel bilgiler
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 50
    },
    description: {
      type: String,
      trim: true,
      maxlength: 200
    },
    icon: {
      type: String,
      required: true,
      default: '👥'
    },
    color: {
      type: String,
      required: true,
      default: '#3B82F6',
      match: /^#[0-9A-F]{6}$/i
    },
    
    // Üyeler
    members: [{
      userId: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
      },
      role: {
        type: String,
        enum: ['admin', 'member'],
        default: 'member'
      },
      joinedAt: {
        type: Date,
        default: Date.now
      },
      isActive: {
        type: Boolean,
        default: true
      }
    }],
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    
    // Ayarlar
    settings: {
      allowMemberInvites: {
        type: Boolean,
        default: true
      },
      requireApprovalForExpenses: {
        type: Boolean,
        default: false
      },
      defaultCurrency: {
        type: String,
        default: 'TRY',
        enum: ['TRY', 'USD', 'EUR', 'GBP']
      },
      splitMethod: {
        type: String,
        enum: ['equal', 'percentage', 'custom'],
        default: 'equal'
      },
      notifications: {
        newExpense: {
          type: Boolean,
          default: true
        },
        newMember: {
          type: Boolean,
          default: true
        },
        expenseReminder: {
          type: Boolean,
          default: false
        }
      }
    },
    
    // İstatistikler
    stats: {
      totalExpenses: {
        type: Number,
        default: 0
      },
      totalAmount: {
        type: Number,
        default: 0
      },
      memberCount: {
        type: Number,
        default: 0
      },
      lastActivity: {
        type: Date,
        default: Date.now
      }
    },
    
    // Durum
    status: {
      type: String,
      enum: ['active', 'archived', 'deleted'],
      default: 'active'
    },
    isPublic: {
      type: Boolean,
      default: false
    },
    inviteCode: {
      type: String,
      unique: true,
      sparse: true
    },
    
    // Sistem alanları
    deletedAt: {
      type: Date
    }
  },
  {
    timestamps: true
  }
);

// Index'ler
groupSchema.index({ 'members.userId': 1 });
groupSchema.index({ createdBy: 1 });
groupSchema.index({ status: 1 });
groupSchema.index({ inviteCode: 1 });
groupSchema.index({ name: 'text', description: 'text' });

// Compound index'ler
groupSchema.index({ 'members.userId': 1, status: 1 });
groupSchema.index({ createdBy: 1, status: 1 });

// Virtual fields
groupSchema.virtual('activeMembers').get(function() {
  return this.members.filter(member => member.isActive);
});

groupSchema.virtual('adminMembers').get(function() {
  return this.members.filter(member => member.role === 'admin' && member.isActive);
});

// Pre-save middleware
groupSchema.pre('save', function (next) {
  // İstatistikleri güncelle
  const self = this as any;
  this.stats.memberCount = self.activeMembers.length;
  
  // Invite code oluştur
  if (this.isNew && !this.inviteCode) {
    this.inviteCode = this.generateInviteCode();
  }
  
  next();
});

// Pre-save middleware - soft delete
groupSchema.pre('save', function (next) {
  if (this.isModified('status') && this.status === 'deleted') {
    this.deletedAt = new Date();
  }
  next();
});

// Instance methods
groupSchema.methods.generateInviteCode = function(): string {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
};

groupSchema.methods.addMember = function(userId: Types.ObjectId | string, role: 'admin' | 'member' = 'member') {
  // Üye zaten var mı kontrol et
  const existingMember = this.members.find((member: any) =>
    member.userId.toString() === userId.toString()
  );
  
  if (existingMember) {
    if (!existingMember.isActive) {
      existingMember.isActive = true;
      existingMember.joinedAt = new Date();
    }
    return existingMember;
  }
  
  // Yeni üye ekle
  const newMember = {
    userId,
    role,
    joinedAt: new Date(),
    isActive: true
  };
  
  this.members.push(newMember);
  return newMember;
};

groupSchema.methods.removeMember = function(userId: Types.ObjectId | string) {
  const memberIndex = this.members.findIndex((member: any) =>
    member.userId.toString() === userId.toString()
  );

  if (memberIndex !== -1) {
    this.members[memberIndex].isActive = false;
    return true;
  }

  return false;
};

groupSchema.methods.isMember = function(userId: Types.ObjectId | string): boolean {
  return this.members.some((member: any) =>
    member.userId.toString() === userId.toString() && member.isActive
  );
};

groupSchema.methods.isAdmin = function(userId: Types.ObjectId | string): boolean {
  return this.members.some((member: any) =>
    member.userId.toString() === userId.toString() &&
    member.role === 'admin' &&
    member.isActive
  );
};

groupSchema.methods.updateStats = async function() {
  const Expense = mongoose.model('Expense');
  
  const stats = await Expense.aggregate([
    {
      $match: {
        groupId: this._id,
        status: 'active'
      }
    },
    {
      $group: {
        _id: null,
        totalExpenses: { $sum: 1 },
        totalAmount: { $sum: '$amount' }
      }
    }
  ]);
  
  if (stats.length > 0) {
    this.stats.totalExpenses = stats[0].totalExpenses;
    this.stats.totalAmount = stats[0].totalAmount;
  }
  
  this.stats.lastActivity = new Date();
  await this.save();
};

// Static methods
groupSchema.statics.getUserGroups = function(userId: Types.ObjectId) {
  return this.find({
    'members.userId': userId,
    'members.isActive': true,
    status: 'active'
  })
  .populate('members.userId', 'name email profileImage')
  .populate('createdBy', 'name email profileImage')
  .sort({ 'stats.lastActivity': -1 });
};

groupSchema.statics.findByInviteCode = function(inviteCode: string) {
  return this.findOne({
    inviteCode,
    status: 'active'
  });
};

export const Group = mongoose.model<IGroup>('Group', groupSchema);