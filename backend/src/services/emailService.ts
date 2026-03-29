import nodemailer from 'nodemailer';
import { config } from '../config/config';

const transporter = nodemailer.createTransport({
  host: config.email.host,
  port: config.email.port,
  auth: {
    user: config.email.user,
    pass: config.email.pass,
  },
});

export const sendVerificationEmail = async (
  to: string,
  name: string,
  token: string
): Promise<void> => {
  const verifyUrl = `${config.appUrl}/verify-email?token=${token}`;

  await transporter.sendMail({
    from: `"FinHelper" <${config.email.from}>`,
    to,
    subject: 'Verify your email address',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #4F46E5;">Welcome to FinHelper, ${name}!</h2>
        <p>Please verify your email address by clicking the button below.</p>
        <a href="${verifyUrl}"
           style="display: inline-block; padding: 12px 24px; background-color: #4F46E5;
                  color: white; text-decoration: none; border-radius: 6px; margin: 16px 0;">
          Verify Email
        </a>
        <p style="color: #6B7280; font-size: 14px;">
          This link expires in 24 hours. If you didn't create an account, ignore this email.
        </p>
        <p style="color: #6B7280; font-size: 12px;">
          Or copy this link: <a href="${verifyUrl}">${verifyUrl}</a>
        </p>
      </div>
    `,
  });
};

export const sendPasswordResetEmail = async (
  to: string,
  name: string,
  token: string
): Promise<void> => {
  const resetUrl = `${config.appUrl}/reset-password?token=${token}`;

  await transporter.sendMail({
    from: `"FinHelper" <${config.email.from}>`,
    to,
    subject: 'Reset your password',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #4F46E5;">Password Reset Request</h2>
        <p>Hi ${name},</p>
        <p>We received a request to reset your password. Click the button below to proceed.</p>
        <a href="${resetUrl}"
           style="display: inline-block; padding: 12px 24px; background-color: #EF4444;
                  color: white; text-decoration: none; border-radius: 6px; margin: 16px 0;">
          Reset Password
        </a>
        <p style="color: #6B7280; font-size: 14px;">
          This link expires in 10 minutes. If you didn't request a password reset, ignore this email.
        </p>
        <p style="color: #6B7280; font-size: 12px;">
          Or copy this link: <a href="${resetUrl}">${resetUrl}</a>
        </p>
      </div>
    `,
  });
};
