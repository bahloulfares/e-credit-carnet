import { Decimal } from '@prisma/client/runtime/library';

/**
 * Recursively converts all Decimal values to numbers in an object or array
 */
export function convertDecimalsToNumbers<T>(data: T): T {
  if (data === null || data === undefined) {
    return data;
  }

  // Preserve Date objects as-is
  if (data instanceof Date) {
    return data;
  }

  // Handle Decimal instances
  if (data instanceof Decimal) {
    return Number(data) as T;
  }

  // Handle arrays
  if (Array.isArray(data)) {
    return data.map(item => convertDecimalsToNumbers(item)) as T;
  }

  // Handle objects
  if (typeof data === 'object') {
    const result: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(data)) {
      result[key] = convertDecimalsToNumbers(value);
    }
    return result as T;
  }

  // Return primitive values as-is
  return data;
}
