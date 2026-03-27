import mongoose from "mongoose";
import { config } from "./config";

// Connection options
const options = {
  maxPoolSize: 10,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
};

export const connectDB = async (): Promise<void> => {
  try {
    const conn = await mongoose.connect(config.mongoURI, options);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    
    // Connection event listeners
    mongoose.connection.on('error', (err) => {
      console.error('MongoDB connection error:', err);
    });
    
    mongoose.connection.on('disconnected', () => {
      console.log('MongoDB disconnected');
    });
    
    mongoose.connection.on('reconnected', () => {
      console.log('MongoDB reconnected');
    });
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
      await mongoose.connection.close();
      console.log('MongoDB connection closed through app termination');
      process.exit(0);
    });
    
  } catch (error) {
    console.error("Error connecting to MongoDB:", error);
    process.exit(1);
  }
};

export const disconnectDB = async (): Promise<void> => {
  try {
    await mongoose.disconnect();
    console.log("MongoDB Disconnected");
  } catch (error) {
    console.error("Error disconnecting from MongoDB:", error);
    process.exit(1);
  }
};

// Database health check
export const checkDatabaseHealth = async (): Promise<boolean> => {
  try {
    const state = mongoose.connection.readyState;
    return state === 1; // 1 = connected
  } catch (error) {
    console.error("Database health check failed:", error);
    return false;
  }
};

// Create indexes for better performance
export const createIndexes = async (): Promise<void> => {
  try {
    const { User } = await import('../models/User');
    const { Expense } = await import('../models/Expense');
    const { Group } = await import('../models/Group');
    const { Category } = await import('../models/Category');
    const { Budget } = await import('../models/Budget');
    const { Notification } = await import('../models/Notification');
    
    // User indexes
    await User.createIndexes();
    console.log('User indexes created');
    
    // Expense indexes
    await Expense.createIndexes();
    console.log('Expense indexes created');
    
    // Group indexes
    await Group.createIndexes();
    console.log('Group indexes created');
    
    // Category indexes
    await Category.createIndexes();
    console.log('Category indexes created');
    
    // Budget indexes
    await Budget.createIndexes();
    console.log('Budget indexes created');
    
    // Notification indexes
    await Notification.createIndexes();
    console.log('Notification indexes created');
    
    console.log('All database indexes created successfully');
  } catch (error) {
    console.error('Error creating database indexes:', error);
    throw error;
  }
};

// Seed default data
export const seedDefaultData = async (): Promise<void> => {
  try {
    const { Category } = await import('../models/Category');
    
    // Check if default categories exist
    const existingCategories = await Category.find({ isDefault: true });
    
    if (existingCategories.length === 0) {
      const defaultCategories = [
        {
          name: 'Yemek',
          description: 'Restoran, market, yemek siparişi',
          icon: '🍽️',
          color: '#FF6B6B',
          type: 'expense',
          isDefault: true
        },
        {
          name: 'Ulaşım',
          description: 'Taksi, otobüs, benzin, park',
          icon: '🚗',
          color: '#4ECDC4',
          type: 'expense',
          isDefault: true
        },
        {
          name: 'Konaklama',
          description: 'Otel, Airbnb, tatil',
          icon: '🏨',
          color: '#45B7D1',
          type: 'expense',
          isDefault: true
        },
        {
          name: 'Sağlık',
          description: 'Doktor, ilaç, spor',
          icon: '💊',
          color: '#96CEB4',
          type: 'expense',
          isDefault: true
        },
        {
          name: 'Eğlence',
          description: 'Sinema, konser, oyun',
          icon: '🎬',
          color: '#FFEAA7',
          type: 'expense',
          isDefault: true
        },
        {
          name: 'Alışveriş',
          description: 'Giyim, elektronik, ev eşyası',
          icon: '🛍️',
          color: '#DDA0DD',
          type: 'expense',
          isDefault: true
        },
        {
          name: 'Faturalar',
          description: 'Elektrik, su, internet, telefon',
          icon: '📄',
          color: '#98D8C8',
          type: 'expense',
          isDefault: true
        },
        {
          name: 'Diğer',
          description: 'Diğer harcamalar',
          icon: '📦',
          color: '#F7DC6F',
          type: 'expense',
          isDefault: true
        }
      ];
      
      await Category.insertMany(defaultCategories);
      console.log('Default categories seeded successfully');
    }
  } catch (error) {
    console.error('Error seeding default data:', error);
    throw error;
  }
};