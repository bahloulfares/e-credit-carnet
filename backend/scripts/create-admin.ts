/* eslint-disable no-console */
import { PrismaClient } from '@prisma/client';
import bcryptjs from 'bcryptjs';

const prisma = new PrismaClient();

function required(name: string): string {
  const value = process.env[name];
  if (!value || value.trim().length === 0) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

async function main() {
  const email = required('ADMIN_EMAIL').toLowerCase();
  const password = required('ADMIN_PASSWORD');
  const firstName = process.env.ADMIN_FIRST_NAME?.trim() || 'Admin';
  const lastName = process.env.ADMIN_LAST_NAME?.trim() || 'Super';
  const phone = process.env.ADMIN_PHONE?.trim() || null;

  const hashedPassword = await bcryptjs.hash(password, 10);

  const user = await prisma.user.upsert({
    where: { email },
    update: {
      firstName,
      lastName,
      phone,
      password: hashedPassword,
      role: 'SUPER_ADMIN',
      isActive: true,
      subscriptionStatus: 'ACTIVE',
    },
    create: {
      email,
      firstName,
      lastName,
      phone,
      password: hashedPassword,
      role: 'SUPER_ADMIN',
      isActive: true,
      subscriptionStatus: 'ACTIVE',
    },
    select: {
      id: true,
      email: true,
      role: true,
      isActive: true,
    },
  });

  console.log('✅ Super admin ready:', user);
}

main()
  .catch((error) => {
    console.error('❌ Failed to create/promote super admin:', error.message || error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
