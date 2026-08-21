import axios from 'axios';
import { logger } from '../lib/logger';

const ZAVU_API_URL = process.env.ZAVU_API_URL || 'https://api.zavu.dev/v1/messages';
const ZAVU_API_KEY = process.env.ZAVU_API_KEY || 'zv_live_1da4f5eac5606af680e85a1c72eb0e6e7d77dd61a19e4f4d';

export interface SendZavuMessageOptions {
  to: string;
  text: string;
  channel?: 'whatsapp' | 'sms' | 'auto';
}

/**
 * Send an omnichannel message (SMS or WhatsApp) via Zavu Dev API
 */
export async function sendZavuMessage(options: SendZavuMessageOptions): Promise<{ success: boolean; data?: any; error?: string }> {
  try {
    if (!ZAVU_API_KEY) {
      logger.warn('Zavu API Key is missing. Skipping message send.');
      return { success: false, error: 'ZAVU_API_KEY is not configured' };
    }

    // Format phone number with country code if needed (default to India +91 if 10 digits)
    let formattedTo = options.to.trim();
    if (/^\d{10}$/.test(formattedTo)) {
      formattedTo = `+91${formattedTo}`;
    }

    const payload: Record<string, any> = {
      to: formattedTo,
      text: options.text,
    };

    if (options.channel && options.channel !== 'auto') {
      payload.channel = options.channel;
    }

    const headers: Record<string, string> = {
      Authorization: `Bearer ${ZAVU_API_KEY}`,
      'Content-Type': 'application/json',
    };

    if (process.env.ZAVU_SENDER) {
      headers['Zavu-Sender'] = process.env.ZAVU_SENDER;
    }

    const response = await axios.post(ZAVU_API_URL, payload, {
      headers,
      timeout: 10000,
    });

    logger.info({ to: formattedTo, channel: options.channel || 'auto' }, '✅ Zavu message sent successfully');
    return { success: true, data: response.data };
  } catch (error: any) {
    const errorMsg = error.response?.data?.message || error.response?.data?.error || error.message;
    logger.warn({ error: errorMsg, to: options.to }, '⚠️ Zavu message delivery error');
    return { success: false, error: errorMsg };
  }
}

/**
 * Send OTP via Zavu (WhatsApp / SMS)
 */
export async function sendZavuOTP(phoneOrEmail: string, otp: string): Promise<boolean> {
  const text = `Your ORBIT verification code is: ${otp}. Valid for 5 minutes. Do not share this code.`;
  const result = await sendZavuMessage({
    to: phoneOrEmail,
    text,
    channel: 'auto',
  });
  return result.success;
}

/**
 * Send Booking Status Update via Zavu (WhatsApp / SMS)
 */
export async function sendZavuBookingNotification(phone: string, title: string, bookingId: string, status: string): Promise<boolean> {
  const text = `🎬 ORBIT Update: ${title}\nBooking ID: #${bookingId.slice(0, 8)}\nStatus: ${status}\nTrack live: https://orbit-quickcontent.com/booking/${bookingId}`;
  const result = await sendZavuMessage({
    to: phone,
    text,
    channel: 'whatsapp',
  });
  return result.success;
}
