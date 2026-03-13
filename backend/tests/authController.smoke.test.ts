import { beforeEach, describe, expect, it, jest } from '@jest/globals';
import authController from '../src/controllers/authController';
import authService from '../src/services/authService';

type MockResponse = {
  status: jest.Mock;
  json: jest.Mock;
};

type LoginRequest = {
  body: {
    email: string;
    password?: string;
  };
};

jest.mock('../src/services/authService', () => ({
  __esModule: true,
  default: {
    register: jest.fn(),
    login: jest.fn(),
    getUserById: jest.fn(),
    updateUser: jest.fn(),
  },
}));

jest.mock('../src/utils/jwt', () => ({
  generateToken: jest.fn(() => 'fake-token'),
}));

jest.mock('../src/utils/logger', () => ({
  __esModule: true,
  default: {
    info: jest.fn(),
    error: jest.fn(),
  },
}));

describe('AuthController smoke', () => {
  const loginMock = authService.login as jest.MockedFunction<
    typeof authService.login
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

  it('returns 400 when email/password are missing on login', async () => {
    const req: LoginRequest = { body: { email: '' } };
    const res = mockRes();

    await authController.login(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      error: 'Email and password are required',
    });
  });

  it('returns 200 when login succeeds', async () => {
    const user: Awaited<ReturnType<typeof authService.login>> = {
      id: 'u1',
      email: 'u@test.com',
      firstName: 'Test',
      lastName: 'User',
      isActive: true,
      role: 'EPICIER',
      phone: null,
      shopName: null,
      shopAddress: null,
      shopPhone: null,
      subscriptionStatus: 'TRIAL',
      subscriptionEndDate: null,
      trialStartDate: new Date('2026-03-01T00:00:00.000Z'),
      trialEndDate: new Date('2026-03-15T00:00:00.000Z'),
      tenantId: null,
      createdAt: new Date('2026-03-01T00:00:00.000Z'),
      updatedAt: new Date('2026-03-01T00:00:00.000Z'),
    };

    loginMock.mockResolvedValue(user);

    const req: LoginRequest = {
      body: { email: 'u@test.com', password: 'secret123' },
    };
    const res = mockRes();

    await authController.login(req as never, res as never);

    expect(authService.login).toHaveBeenCalledWith('u@test.com', 'secret123');
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Login successful',
        token: 'fake-token',
      }),
    );
  });
});
