interface RateLimitRecord {
  count: number;
  resetTime: number;
}

export class InMemoryRateLimiter {
  private static store = new Map<string, RateLimitRecord>();

  /**
   * Checks if an IP or identifier has exceeded rate limits.
   * @param key Unique identifier (e.g. client IP + endpoint)
   * @param maxRequests Maximum allowed requests in window
   * @param windowMs Time window in milliseconds
   */
  public static check(
    key: string,
    maxRequests = 60,
    windowMs = 60000
  ): { isAllowed: boolean; remaining: number; resetInMs: number } {
    const now = Date.now();
    const record = this.store.get(key);

    if (!record || now > record.resetTime) {
      this.store.set(key, { count: 1, resetTime: now + windowMs });
      return { isAllowed: true, remaining: maxRequests - 1, resetInMs: windowMs };
    }

    if (record.count >= maxRequests) {
      return {
        isAllowed: false,
        remaining: 0,
        resetInMs: Math.max(0, record.resetTime - now),
      };
    }

    record.count++;
    return {
      isAllowed: true,
      remaining: maxRequests - record.count,
      resetInMs: Math.max(0, record.resetTime - now),
    };
  }

  public static clear(): void {
    this.store.clear();
  }
}
