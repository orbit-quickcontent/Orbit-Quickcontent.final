import { authenticator } from 'otplib';
import qrcode from 'qrcode';
import prisma from '../lib/prisma';
import { logger } from '../lib/logger';

/**
 * Service to handle Two-Factor Authentication (TOTP)
 */
export class AuthService {
  /**
   * Generates a new TOTP secret and returns the secret along with a QR code data URL.
   * @param email The user's email address to display in the authenticator app
   * @returns { secret, qrCodeUrl }
   */
  static async generateTotpSecret(email: string) {
    const secret = authenticator.generateSecret();
    
    // Create the otpauth:// URI
    const serviceName = 'ORBIT Platform';
    const otpauth = authenticator.keyuri(email, serviceName, secret);
    
    // Generate QR Code
    const qrCodeUrl = await qrcode.toDataURL(otpauth);
    
    return { secret, qrCodeUrl };
  }

  /**
   * Verifies a TOTP token against a secret.
   * @param token The 6-digit code provided by the user
   * @param secret The stored secret for the user
   * @returns boolean indicating if the token is valid
   */
  static verifyTotpToken(token: string, secret: string): boolean {
    try {
      return authenticator.verify({ token, secret });
    } catch (err) {
      logger.error(err, 'Error verifying TOTP token');
      return false;
    }
  }

  /**
   * Enables 2FA for a user in the database.
   * @param userId The ID of the user
   * @param secret The verified TOTP secret to store
   */
  static async enable2FA(userId: string, secret: string) {
    await prisma.user.update({
      where: { id: userId },
      data: { 
        twoFactorSecret: secret,
        twoFactorEnabled: true 
      }
    });
  }
}
