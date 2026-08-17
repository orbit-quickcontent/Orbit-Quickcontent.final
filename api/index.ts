import type { VercelRequest, VercelResponse } from '@vercel/node';
import app from '../backend/src/server';

// Serverless function entrypoint for Vercel
export default function handler(req: VercelRequest, res: VercelResponse) {
  try {
    return (app as any)(req, res);
  } catch (error: any) {
    console.error('Unhandled serverless function crash:', error);
    if (!res.headersSent) {
      res.status(500).json({
        error: 'Serverless invocation error',
        message: error?.message || 'Unknown internal error',
      });
    }
  }
}
