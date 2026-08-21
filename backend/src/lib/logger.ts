import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'info' : 'debug'),
  transport: process.env.NODE_ENV !== 'production'
    ? { target: 'pino-pretty', options: { colorize: true, translateTime: 'SYS:standard', ignore: 'pid,hostname' } }
    : undefined,
  redact: {
    paths: [
      'email', 'phone', 'password', 'passwordHash', 'otpHash', 'otp',
      'encryptedAccountNumber', 'panNumber', 'JWT', 'token', 'refreshToken',
      'authorization', 'req.headers.authorization', 'CASHFREE_CLIENT_SECRET',
      'SMTP_PASS', 'ZAVU_API_KEY',
    ],
    censor: '[REDACTED]',
  },
});
