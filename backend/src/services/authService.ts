import { User } from '@prisma/client';
import { ApiError } from '../utils/errors';
import { hashPassword, comparePasswords } from '../utils/bcrypt';
import prisma from '../lib/prisma';

export class AuthService {
  async register(userData: {
    email: string;
    firstName: string;
    lastName: string;
    password: string;
    shopName?: string;
    phone?: string;
  }): Promise<Omit<User, 'password'>> {
    const existingUser = await prisma.user.findUnique({
      where: { email: userData.email },
    });

    if (existingUser) {
      throw new ApiError(400, 'User already exists');
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

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  async login(email: string, password: string): Promise<Omit<User, 'password'>> {
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new ApiError(401, 'Invalid credentials');
    }

    const isPasswordValid = await comparePasswords(password, user.password);

    if (!isPasswordValid) {
      throw new ApiError(401, 'Invalid credentials');
    }

    if (!user.isActive) {
      throw new ApiError(403, 'Account is deactivated');
    }

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  async getUserById(id: string): Promise<Omit<User, 'password'> | null> {
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      return null;
    }

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  async updateUser(
    id: string,
    data: Partial<User>,
  ): Promise<Omit<User, 'password'>> {
    const user = await prisma.user.update({
      where: { id },
      data,
    });

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }
}

export default new AuthService();
