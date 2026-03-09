import jwt, { SignOptions, Secret } from 'jsonwebtoken';
import dotenv from 'dotenv';

dotenv.config();

interface TokenPayload {
  id: string;
  email: string;
  role: string;
}

const getJwtSecret = (): Secret => {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new Error('JWT_SECRET is required');
  }

  return secret;
};

export const generateToken = (payload: TokenPayload): string => {
  const secret = getJwtSecret();
  const expiresIn = (process.env.JWT_EXPIRATION || '7d') as SignOptions['expiresIn'];
  return jwt.sign(payload, secret, { expiresIn });
};

export const verifyToken = (token: string): TokenPayload => {
  try {
    const secret = getJwtSecret();
    const decoded = jwt.verify(token, secret);
    return decoded as TokenPayload;
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

export const decodeToken = (token: string): TokenPayload | null => {
  try {
    const decoded = jwt.decode(token);
    return decoded as TokenPayload | null;
  } catch (error) {
    return null;
  }
};
