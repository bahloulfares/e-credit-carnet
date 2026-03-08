import bcryptjs from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

export const hashPassword = async (password: string): Promise<string> => {
  const saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '10');
  return bcryptjs.hash(password, saltRounds);
};

export const comparePasswords = async (
  plainPassword: string,
  hashedPassword: string,
): Promise<boolean> => {
  return bcryptjs.compare(plainPassword, hashedPassword);
};
