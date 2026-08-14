import prisma from './lib/prisma';
import bcrypt from 'bcryptjs';
import { logger } from './lib/logger';

async function seed() {
  logger.info('🌱 Seeding ORBIT database...');

  // Create packages
  const packages = await Promise.all([
    prisma.package.upsert({
      where: { tier: 'PERSONALIZED' },
      update: {},
      create: {
        name: 'Personalized',
        tier: 'PERSONALIZED',
        price: 199900, // ₹1,999 in paise
        priceDisplay: 1999,
        partnerPayout: 500,
        focus: 'Solo Creator / Personal Brand',
        deliveryTime: '120 minutes',
        features: [
          '3 Short-form Reels (up to 60s each)',
          'Basic Color Grading',
          'Text Overlays & Captions',
          'Licensed Background Music',
          'Brand Logo Watermark',
          'MP4 Download (1080p)',
        ],
        popular: false,
        isActive: true,
      },
    }),
    prisma.package.upsert({
      where: { tier: 'PROFESSIONAL' },
      update: {},
      create: {
        name: 'Professional',
        tier: 'PROFESSIONAL',
        price: 499900, // ₹4,999 in paise
        priceDisplay: 4999,
        partnerPayout: 500,
        focus: 'Business / Product Launch',
        deliveryTime: '120 minutes',
        features: [
          '6 Short-form Reels (up to 90s each)',
          'Advanced Color Grading & LUTs',
          'Motion Graphics & Animated Text',
          'Voiceover Integration',
          'Custom Brand Kit (Fonts, Colors, Logo)',
          'Multi-platform Export (1080p & 4K)',
          'Thumbnail Pack (5 custom thumbnails)',
        ],
        popular: true,
        isActive: true,
      },
    }),
  ]);

  logger.info(`Created ${packages.length} packages`);

  // Create admin user
  const admin = await prisma.user.upsert({
    where: { email: 'admin@orbit-platform.com' },
    update: {},
    create: {
      email: 'admin@orbit-platform.com',
      name: 'ORBIT Admin',
      role: 'ADMIN',
      isActive: true,
    },
  });
  logger.info(`Admin user: ${admin.email}`);

  // Create master partner account (for testing)
  if (process.env.PARTNER_MASTER_EMAIL) {
    const masterPartnerUser = await prisma.user.upsert({
      where: { email: process.env.PARTNER_MASTER_EMAIL },
      update: {},
      create: {
        email: process.env.PARTNER_MASTER_EMAIL,
        name: 'ORBIT Partner (Test)',
        role: 'PARTNER',
        isActive: true,
      },
    });

    const masterPartner = await prisma.partner.upsert({
      where: { userId: masterPartnerUser.id },
      update: {},
      create: {
        userId: masterPartnerUser.id,
        displayName: 'Test Partner',
        status: 'ACTIVE',
        verificationStatus: 'VERIFIED',
        canAcceptBookings: true,
        isOnline: false,
        isAvailable: false,
      },
    });

    // Create wallet
    await prisma.partnerWallet.upsert({
      where: { partnerId: masterPartner.id },
      update: {},
      create: { partnerId: masterPartner.id, available: 0, reserved: 0, totalEarned: 0, totalWithdrawn: 0 },
    });

    logger.info(`Master partner: ${masterPartnerUser.email} → partner ID: ${masterPartner.id}`);
  }

  logger.info('✅ Database seeded successfully');
}

seed()
  .catch((err) => { logger.error(err, '❌ Seed failed'); process.exit(1); })
  .finally(() => prisma.$disconnect());
