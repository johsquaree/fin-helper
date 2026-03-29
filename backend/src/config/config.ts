import dotenv from 'dotenv';

dotenv.config();

interface Config {
  port: number;
  mongoURI: string;
  jwtSecret: string;
  jwtRefreshSecret: string;
  nodeEnv: string;
  allowedOrigins: string[];
  appUrl: string;
  email: {
    host: string;
    port: number;
    user: string;
    pass: string;
    from: string;
  };
}

const config: Config = {
  port: Number(process.env.PORT) || 3000,
  mongoURI: process.env.MONGO_URI || 'mongodb://localhost:27017/finhelper',
  jwtSecret: process.env.JWT_SECRET || 'change-this-secret-in-production',
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'change-this-refresh-secret-in-production',
  nodeEnv: process.env.NODE_ENV || 'development',
  allowedOrigins: process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',')
    : ['http://localhost:3000', 'http://localhost:8081'],
  appUrl: process.env.APP_URL || 'http://localhost:3000',
  email: {
    host: process.env.EMAIL_HOST || 'sandbox.smtp.mailtrap.io',
    port: Number(process.env.EMAIL_PORT) || 2525,
    user: process.env.EMAIL_USER || '',
    pass: process.env.EMAIL_PASS || '',
    from: process.env.EMAIL_FROM || 'noreply@finhelper.com',
  },
};

export { config };
