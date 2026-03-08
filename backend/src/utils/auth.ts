import { User } from '@prisma/client';
import { hashPassword, comparePasswords } from './bcrypt';
import { generateToken } from './jwt';
import prisma from '../lib/prisma';

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface TokenResponse {
  token: string;
  user: Omit<User, 'password'>;
}

export const loginUser = async (
  credentials: LoginCredentials,
): Promise<TokenResponse> => {
  const user = await prisma.user.findUnique({
    where: { email: credentials.email },
  });

  if (!user) {
    throw new Error('User not found');
  }

  const isPasswordValid = await comparePasswords(
    credentials.password,
    user.password,
  );

  if (!isPasswordValid) {
    throw new Error('Invalid password');
  }

  const token = generateToken({
    id: user.id,
    email: user.email,
    role: user.role,
  });

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { password, ...userWithoutPassword } = user;

  return {
    token,
    user: userWithoutPassword,
  };
};

export const registerUser = async (userData: {
  email: string;
  firstName: string;
  lastName: string;
  password: string;
  shopName?: string;
  phone?: string;
}): Promise<TokenResponse> => {
  const existingUser = await prisma.user.findUnique({
    where: { email: userData.email },
  });

  if (existingUser) {
    throw new Error('User already exists');
  }

  const hashedPassword = await hashPassword(userData.password);

  const user = await prisma.user.create({
    data: {
      email: userData.email,
      firstName: userData.firstName,
      lastName: userData.lastName,
      password: hashedPassword,
      shopName: userData.shopName,
      phone: userData.phone,
      role: 'EPICIER',
      subscriptionStatus: 'TRIAL',
      trialStartDate: new Date(),
      trialEndDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
    },
  });

  // Create trial subscription
  await prisma.subscription.create({
    data: {
      userId: user.id,
      plan: 'trial',
      startDate: new Date(),
      endDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
      amountDT: 0,
      paymentMethod: 'trial',
    },
  });

  const token = generateToken({
    id: user.id,
    email: user.email,
    role: user.role,
  });

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { password, ...userWithoutPassword } = user;

  return {
    token,
    user: userWithoutPassword,
  };
};
