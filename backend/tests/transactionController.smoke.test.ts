import { beforeEach, describe, expect, it, jest } from '@jest/globals';
import transactionController from '../src/controllers/transactionController';
import transactionService from '../src/services/transactionService';

type MockResponse = {
  status: jest.Mock;
  json: jest.Mock;
};

type TransactionListRequest = {
  user?: { id: string };
  query: {
    clientId?: string;
    skip?: string;
    take?: string;
    month?: string;
    year?: string;
  };
};

jest.mock('../src/services/transactionService', () => ({
  __esModule: true,
  default: {
    createTransaction: jest.fn(),
    listTransactions: jest.fn(),
    getTransactionById: jest.fn(),
    updateTransaction: jest.fn(),
    deleteTransaction: jest.fn(),
  },
}));

jest.mock('../src/utils/logger', () => ({
  __esModule: true,
  default: {
    info: jest.fn(),
    error: jest.fn(),
  },
}));

describe('TransactionController smoke', () => {
  const listTransactionsMock =
    transactionService.listTransactions as jest.MockedFunction<
      typeof transactionService.listTransactions
    >;

  const mockRes = (): MockResponse => {
    const res = {} as MockResponse;
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 401 when user is missing', async () => {
    const req: TransactionListRequest = { user: undefined, query: {} };
    const res = mockRes();

    await transactionController.getTransactions(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ error: 'Unauthorized' });
  });

  it('passes month/year filters to service', async () => {
    const transactions: Awaited<
      ReturnType<typeof transactionService.listTransactions>
    > = [];

    listTransactionsMock.mockResolvedValue(transactions);

    const req: TransactionListRequest = {
      user: { id: 'u1' },
      query: { clientId: 'c1', skip: '0', take: '20', month: '3', year: '2026' },
    };
    const res = mockRes();

    await transactionController.getTransactions(req as never, res as never);

    expect(transactionService.listTransactions).toHaveBeenCalledWith('u1', 'c1', {
      skip: 0,
      take: 20,
      type: undefined,
      isPaid: undefined,
      month: 3,
      year: 2026,
    });
    expect(res.status).toHaveBeenCalledWith(200);
  });
});
