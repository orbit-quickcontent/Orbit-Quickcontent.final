// ==============================================================================
// ORBIT Cloudflare Edge Worker API Gateway
// Compatible with Cloudflare V8 Workers runtime (zero body-parser/stream issues)
// ==============================================================================

export interface Env {
  NODE_ENV?: string;
  ALLOWED_ORIGINS?: string;
}

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Idempotency-Key',
};

function jsonResponse(data: any, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
  });
}

export default {
  async fetch(request: Request, env: Env, ctx: any): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method.toUpperCase();

    // Handle CORS Preflight
    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    // Root Health / Info
    if (path === '/' || path === '/health') {
      return jsonResponse({
        status: 'ok',
        service: 'orbit-cloudflare-edge',
        message: 'ORBIT Platform API is online',
        version: '1.0.0',
        environment: env.NODE_ENV || 'production',
        timestamp: new Date().toISOString(),
      });
    }

    // Packages Endpoint
    if (path === '/api/packages') {
      return jsonResponse([
        {
          id: 'pkg_creator_personalized',
          name: 'Personalized',
          focus: 'Individual creators, personal events',
          price: 199900,
          priceDisplay: 1999,
          partnerPayout: 500,
          popular: false,
          features: [
            '1 cinematic reel (30-60 sec)',
            'Professional color grading',
            'Background score licensing',
            'Same-day delivery (60-90 mins)',
            '1 revision round',
          ],
        },
        {
          id: 'pkg_creator_ugc_pro',
          name: 'Professional (UGC)',
          focus: 'Brands, businesses, template creators',
          price: 499900,
          priceDisplay: 4999,
          partnerPayout: 1800,
          popular: true,
          features: [
            '3 cinematic reels (30-60 sec each)',
            'Brand DNA integration (logo, palette, font)',
            'Professional color grading & stabilization',
            'Licensed premium sound scores',
            'Same-day express delivery (90-120 mins)',
            '2 revision rounds with master editor',
          ],
        },
      ]);
    }

    // Auth: Send OTP
    if (path === '/api/auth/send-otp') {
      return jsonResponse({
        success: true,
        message: 'Verification code sent to your email (Demo code: 123456)',
      });
    }

    // Auth: Verify OTP
    if (path === '/api/auth/verify-otp') {
      let body: any = {};
      try { body = await request.json(); } catch (_) {}
      const email = body.email || 'user@orbit-quickcontent.com';
      const role = body.role || 'CLIENT';

      return jsonResponse({
        success: true,
        accessToken: `orbit_jwt_${Date.now()}`,
        refreshToken: `orbit_refresh_${Date.now()}`,
        user: {
          id: `user_${Date.now()}`,
          name: role === 'PARTNER' ? 'utkarsh gupta' : 'Creator User',
          email,
          role,
        },
        partner: role === 'PARTNER' ? {
          id: 'partner_1',
          status: 'ACTIVE',
          displayName: 'utkarsh gupta',
          rating: 5.0,
          completedProjects: 12,
          activeProjects: 0,
          walletBalance: 8400,
        } : null,
      });
    }

    // Partner Profile
    if (path === '/api/partner/profile') {
      return jsonResponse({
        displayName: 'utkarsh gupta',
        user: {
          name: 'utkarsh gupta',
          email: 'utkarshssg2608@gmail.com',
        },
        rating: 5.0,
        completedProjects: 12,
        activeProjects: 0,
        walletBalance: 8400,
      });
    }

    // Partner Earnings
    if (path === '/api/partner/earnings') {
      return jsonResponse({
        totalEarned: 8400,
        monthEarned: 2800,
        weekEarned: 1400,
        completedCount: 12,
        rating: 5.0,
      });
    }

    // Bookings
    if (path.startsWith('/api/bookings')) {
      if (method === 'POST') {
        return jsonResponse({
          bookingId: `bk_${Date.now()}`,
          status: 'DISPATCHING',
          package: { name: 'Personalized', priceDisplay: 1999 },
          payment: { keyId: 'rzp_test_demo', amount: 199900, currency: 'INR', orderId: 'order_123' },
        });
      }
      return jsonResponse({
        bookings: [
          {
            id: 'bk_1',
            status: 'DELIVERED',
            createdAt: new Date(Date.now() - 86400000).toISOString(),
            address: 'Bandra West, Mumbai',
            package: { name: 'Personalized', priceDisplay: 1999 },
            partnerSalary: 700,
          },
        ],
      });
    }

    // Notifications
    if (path === '/api/notifications') {
      return jsonResponse([
        {
          id: 'n1',
          title: 'Welcome to Orbit',
          body: 'Book your first professional shoot in seconds.',
          isRead: false,
        },
      ]);
    }

    // Default 404
    return jsonResponse({ error: 'Route not found', path }, 404);
  },
};
