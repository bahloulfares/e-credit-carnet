/* eslint-disable no-console */
/// <reference types="node" />

import { PrismaClient } from '@prisma/client';
import bcryptjs from 'bcryptjs';

const prisma = new PrismaClient();

type SeedTx = {
  type: 'CREDIT' | 'PAYMENT';
  amount: number;
  daysAgo: number;
  description: string;
  paymentMethod?: string;
};

function dateDaysAgo(daysAgo: number): Date {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date;
}

async function recalculateClientStats(userId: string, clientId: string): Promise<void> {
  const clientTransactions = await prisma.transaction.findMany({
    where: {
      userId,
      clientId,
      deletedAt: null,
    },
  });

  const totalCredit = clientTransactions
    .filter((t) => t.type === 'CREDIT')
    .reduce((sum, t) => sum + Number(t.amount), 0);

  const totalPayment = clientTransactions
    .filter((t) => t.type === 'PAYMENT')
    .reduce((sum, t) => sum + Number(t.amount), 0);

  await prisma.client.update({
    where: { id: clientId },
    data: {
      totalCredit,
      totalPayment,
      totalDebt: Math.max(0, totalCredit - totalPayment),
    },
  });
}

async function createClientWithTransactions(params: {
  userId: string;
  firstName: string;
  lastName: string;
  phone?: string;
  email?: string;
  address?: string;
  isActive?: boolean;
  transactions: SeedTx[];
}) {
  const client = await prisma.client.create({
    data: {
      userId: params.userId,
      firstName: params.firstName,
      lastName: params.lastName,
      phone: params.phone,
      email: params.email,
      address: params.address,
      isActive: params.isActive ?? true,
      totalDebt: 0,
      totalCredit: 0,
      totalPayment: 0,
    },
  });

  for (const tx of params.transactions) {
    const txDate = dateDaysAgo(tx.daysAgo);
    await prisma.transaction.create({
      data: {
        userId: params.userId,
        clientId: client.id,
        type: tx.type,
        amount: tx.amount,
        description: tx.description,
        transactionDate: txDate,
        isPaid: tx.type === 'PAYMENT',
        paidAt: tx.type === 'PAYMENT' ? txDate : null,
        paymentMethod: tx.paymentMethod,
        dueDate: tx.type === 'CREDIT' ? new Date(txDate.getTime() + 7 * 24 * 60 * 60 * 1000) : null,
      },
    });
  }

  await recalculateClientStats(params.userId, client.id);
  return client;
}

async function main() {
  console.log('🌱 Seeding database...');

  // Clean up existing data
  await prisma.auditLog.deleteMany();
  await prisma.syncLog.deleteMany();
  await prisma.pendingSync.deleteMany();
  await prisma.transaction.deleteMany();
  await prisma.client.deleteMany();
  await prisma.subscription.deleteMany();
  await prisma.supportTicket.deleteMany();
  await prisma.user.deleteMany();
  await prisma.backup.deleteMany();

  // Create Super Admin
  const adminPassword = await bcryptjs.hash('Admin@123', 10);
  const admin = await prisma.user.create({
    data: {
      email: 'admin@procreditapp.com',
      firstName: 'Admin',
      lastName: 'Super',
      password: adminPassword,
      phone: '+216 20 000 000',
      role: 'SUPER_ADMIN',
      subscriptionStatus: 'ACTIVE',
      subscriptionEndDate: new Date('2025-12-31'),
    },
  });

  console.log('✓ Super Admin created:', admin.email);

  // Create test Épicier accounts (deterministic)
  const epicierPassword = await bcryptjs.hash('Epicier@123', 10);

  const epicier1 = await prisma.user.create({
    data: {
      email: 'epicier1@procreditapp.com',
      firstName: 'Ahmed',
      lastName: 'Ben',
      password: epicierPassword,
      phone: '+216 20 123 456',
      role: 'EPICIER',
      shopName: 'Épicerie Ben Ahmed',
      shopAddress: 'Rue de la République, Tunis',
      shopPhone: '+216 71 123 456',
      subscriptionStatus: 'TRIAL',
      trialStartDate: new Date(),
      trialEndDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000), // 15 days trial
    },
  });

  console.log('✓ Épicier 1 created:', epicier1.email);

  const epicier2 = await prisma.user.create({
    data: {
      email: 'epicier2@procreditapp.com',
      firstName: 'Fatima',
      lastName: 'Khmissa',
      password: epicierPassword,
      phone: '+216 20 234 567',
      role: 'EPICIER',
      shopName: 'Épicerie Khmissa',
      shopAddress: 'Avenue Habib Bourguiba, Sfax',
      shopPhone: '+216 74 234 567',
      subscriptionStatus: 'ACTIVE',
      subscriptionEndDate: new Date('2025-06-30'),
    },
  });

  console.log('✓ Épicier 2 created:', epicier2.email);

  // Deterministic clients + transactions for calculation validation
  await createClientWithTransactions({
    userId: epicier1.id,
    firstName: 'Mohamed',
    lastName: 'Mansour',
    phone: '+21620111222',
    email: 'mohamed.mansour@email.com',
    address: 'Tunis',
    transactions: [
      { type: 'CREDIT', amount: 200, daysAgo: 2, description: 'Crédit alimentation' },
      { type: 'CREDIT', amount: 100, daysAgo: 6, description: 'Crédit boissons' },
      { type: 'PAYMENT', amount: 50, daysAgo: 1, description: 'Paiement partiel', paymentMethod: 'D17' },
    ],
  });

  await createClientWithTransactions({
    userId: epicier1.id,
    firstName: 'Leila',
    lastName: 'Zahra',
    phone: '+21620222333',
    email: 'leila.zahra@email.com',
    address: 'Sousse',
    transactions: [
      { type: 'CREDIT', amount: 300, daysAgo: 20, description: 'Crédit mensuel' },
      { type: 'PAYMENT', amount: 120, daysAgo: 3, description: 'Paiement D17', paymentMethod: 'D17' },
      { type: 'PAYMENT', amount: 30, daysAgo: 35, description: 'Paiement ancien', paymentMethod: 'cash' },
    ],
  });

  await createClientWithTransactions({
    userId: epicier1.id,
    firstName: 'Ali',
    lastName: 'Ben Amedi',
    phone: '+21620333444',
    email: 'ali.benamedi@email.com',
    address: 'Sfax',
    transactions: [
      { type: 'CREDIT', amount: 80, daysAgo: 7, description: 'Crédit tabac' },
      { type: 'PAYMENT', amount: 100, daysAgo: 2, description: 'Paiement total', paymentMethod: 'Flouci' },
    ],
  });

  await createClientWithTransactions({
    userId: epicier2.id,
    firstName: 'Nadia',
    lastName: 'Habib',
    phone: '+21620444555',
    email: 'nadia.habib@email.com',
    address: 'Sfax',
    transactions: [
      { type: 'CREDIT', amount: 500, daysAgo: 4, description: 'Crédit gros achat' },
      { type: 'PAYMENT', amount: 200, daysAgo: 2, description: 'Paiement cash', paymentMethod: 'cash' },
    ],
  });

  await createClientWithTransactions({
    userId: epicier2.id,
    firstName: 'Karim',
    lastName: 'Saidani',
    phone: '+21620555666',
    email: 'karim.saidani@email.com',
    address: 'Monastir',
    isActive: false,
    transactions: [
      { type: 'CREDIT', amount: 999, daysAgo: 2, description: 'Client inactif - doit être exclu des stats actives' },
      { type: 'PAYMENT', amount: 111, daysAgo: 1, description: 'Paiement inactif', paymentMethod: 'cash' },
    ],
  });

  console.log('✓ Deterministic clients & transactions created');

  // Create Subscriptions
  await prisma.subscription.create({
    data: {
      userId: epicier1.id,
      plan: 'trial',
      startDate: new Date(),
      endDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
      amountDT: 0,
      paymentMethod: 'trial',
    },
  });

  await prisma.subscription.create({
    data: {
      userId: epicier2.id,
      plan: 'basic',
      startDate: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000),
      endDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
      autoRenew: true,
      paymentMethod: 'd17',
      lastPaymentDate: new Date(),
      nextPaymentDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
      amountDT: 200,
    },
  });

  console.log('✓ Subscriptions created');

  // Create Support Tickets
  await prisma.supportTicket.create({
    data: {
      userId: epicier1.id,
      subject: 'Problème de synchronisation',
      description: 'Les données ne se synchronisent pas correctement avec le serveur',
      category: 'technical',
      priority: 'high',
      status: 'open',
    },
  });

  console.log('✓ Support tickets created');

  // Verification logs (global active-client scope)
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  const activeClientsCount = await prisma.client.count({ where: { isActive: true } });
  const allActiveTransactions = await prisma.transaction.findMany({
    where: {
      deletedAt: null,
      client: {
        is: {
          isActive: true,
        },
      },
    },
  });

  const totalCredit = allActiveTransactions
    .filter((t) => t.type === 'CREDIT')
    .reduce((sum, t) => sum + Number(t.amount), 0);
  const totalPayment = allActiveTransactions
    .filter((t) => t.type === 'PAYMENT')
    .reduce((sum, t) => sum + Number(t.amount), 0);

  const monthlyTx = allActiveTransactions.filter((t) => t.transactionDate >= startOfMonth);
  const monthlyCredit = monthlyTx
    .filter((t) => t.type === 'CREDIT')
    .reduce((sum, t) => sum + Number(t.amount), 0);
  const monthlyPayment = monthlyTx
    .filter((t) => t.type === 'PAYMENT')
    .reduce((sum, t) => sum + Number(t.amount), 0);

  console.log('📊 Seed verification (active clients only):');
  console.log(`   Clients actifs: ${activeClientsCount}`);
  console.log(`   Crédit total: ${totalCredit.toFixed(2)} DT`);
  console.log(`   Paiement total: ${totalPayment.toFixed(2)} DT`);
  console.log(`   Crédit mensuel: ${monthlyCredit.toFixed(2)} DT`);
  console.log(`   Paiement mensuel: ${monthlyPayment.toFixed(2)} DT`);
  console.log(`   Transactions mensuelles: ${monthlyTx.length}`);

  console.log('✅ Database seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
