// ==============================================================================
// ORBIT Cloudflare Edge Worker — Stateful API Gateway
// Connects Client App ↔ Partner App with shared in-memory booking state machine
// ==============================================================================

export interface Env {
  NODE_ENV?: string;
  ALLOWED_ORIGINS?: string;
}

// ── In-Memory State Stores ───────────────────────────────────────────────────
// These persist across requests within the same worker instance (same isolate).
// For production, replace with Durable Objects or D1/KV.

interface UserRecord {
  id: string;
  email: string;
  name: string;
  role: 'CLIENT' | 'PARTNER' | 'EDITOR' | 'ADMIN';
  passwordHash?: string;
  avatar?: string;
  createdAt: string;
  partnerId?: string;
  fcmToken?: string;
}

interface PartnerRecord {
  id: string;
  userId: string;
  displayName: string;
  status: 'ACTIVE' | 'PENDING' | 'SUSPENDED';
  verificationStatus: 'VERIFIED' | 'PENDING' | 'REJECTED';
  isOnline: boolean;
  isAvailable: boolean;
  canAcceptBookings: boolean;
  latitude?: number;
  longitude?: number;
  lastSeenAt?: string;
  rating: number;
  completedProjects: number;
  activeProjects: number;
  walletBalance: number;
  totalEarned: number;
  monthEarned: number;
  weekEarned: number;
  fcmToken?: string;
}

interface BookingRecord {
  id: string;
  userId: string;
  packageId: string;
  partnerId?: string;
  status: string;
  paymentStatus: string;
  latitude: number;
  longitude: number;
  address: string;
  bookingDate: string;
  timeSlot: string;
  notes?: string;
  createdAt: string;
  partnerAssignedAt?: string;
  arrivedAt?: string;
  shootingStartedAt?: string;
  shootingEndedAt?: string;
  cancelledAt?: string;
  cancelledBy?: string;
  cancellationReason?: string;
  dispatchRound: number;
  declinedBy: string[];
  statusHistory: Array<{ from: string | null; to: string; at: string; by: string }>;
}

interface RealtimeEvent {
  id: string;
  channel: string;
  event: string;
  payload: any;
  createdAt: string;
  consumed: boolean;
}

const users = new Map<string, UserRecord>();
const partners = new Map<string, PartnerRecord>();
const bookings = new Map<string, BookingRecord>();
const realtimeEvents: RealtimeEvent[] = [];
const tokens = new Map<string, string>(); // token -> userId

// ── Seed Default Data ────────────────────────────────────────────────────────
function ensureSeeded() {
  if (users.size > 0) return;

  // Default partner user
  const partnerUserId = 'user_partner_default';
  const partnerId = 'partner_default_1';

  users.set(partnerUserId, {
    id: partnerUserId,
    email: 'utkarshssg2608@gmail.com',
    name: 'utkarsh gupta',
    role: 'PARTNER',
    partnerId,
    createdAt: new Date().toISOString(),
  });

  partners.set(partnerId, {
    id: partnerId,
    userId: partnerUserId,
    displayName: 'utkarsh gupta',
    status: 'ACTIVE',
    verificationStatus: 'VERIFIED',
    isOnline: false,
    isAvailable: true,
    canAcceptBookings: true,
    latitude: 18.5596,
    longitude: 73.7857,
    rating: 5.0,
    completedProjects: 12,
    activeProjects: 0,
    walletBalance: 8400,
    totalEarned: 8400,
    monthEarned: 2800,
    weekEarned: 1400,
  });
}

// ── Packages ─────────────────────────────────────────────────────────────────
const PACKAGES = [
  {
    id: 'pkg_quick',
    name: 'Quick Reel',
    tier: 'QUICK',
    price: 99900,
    priceDisplay: 999,
    partnerPayout: 400,
    focus: '1 High-Impact 9:16 Reel',
    deliveryTime: '60 min delivery',
    features: ['1 Short-form Reel (30-60s)', 'Basic Color Grading', 'Trending Audio Sync', '1080p MP4 Export'],
    popular: false,
    isActive: true,
  },
  {
    id: 'pkg_standard',
    name: 'Creator Standard',
    tier: 'PERSONALIZED',
    price: 199900,
    priceDisplay: 1999,
    partnerPayout: 500,
    focus: '3 Polished Reels + B-Roll',
    deliveryTime: '120 min delivery',
    features: ['3 Short-form Reels', 'Advanced Color Grading', 'Motion Captions', '4K Master Export'],
    popular: true,
    isActive: true,
  },
  {
    id: 'pkg_premium',
    name: 'Brand Premium',
    tier: 'PROFESSIONAL',
    price: 499900,
    priceDisplay: 4999,
    partnerPayout: 1000,
    focus: '6 Cinematic Reels + Brand Kit',
    deliveryTime: 'Same Day delivery',
    features: ['6 Master Reels', 'Motion Graphics & Text', 'Sound Design & VO', 'Custom Brand Kit'],
    popular: false,
    isActive: true,
  },
];

// ── Helper Functions ─────────────────────────────────────────────────────────
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Idempotency-Key',
};

function json(data: any, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

function genId(prefix: string): string {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

function issueToken(userId: string): string {
  const token = `orbit_jwt_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
  tokens.set(token, userId);
  return token;
}

function getUserFromRequest(request: Request): UserRecord | null {
  const auth = request.headers.get('Authorization');
  if (!auth?.startsWith('Bearer ')) return null;
  const token = auth.substring(7);
  const userId = tokens.get(token);
  if (!userId) return null;
  return users.get(userId) || null;
}

function getPartnerForUser(userId: string): PartnerRecord | null {
  const user = users.get(userId);
  if (!user?.partnerId) return null;
  return partners.get(user.partnerId) || null;
}

function emitEvent(channel: string, event: string, payload: any) {
  realtimeEvents.push({
    id: genId('evt'),
    channel,
    event,
    payload,
    createdAt: new Date().toISOString(),
    consumed: false,
  });
  // Keep only last 500 events to prevent memory bloat
  if (realtimeEvents.length > 500) {
    realtimeEvents.splice(0, realtimeEvents.length - 500);
  }
}

function recordStatusChange(booking: BookingRecord, from: string | null, to: string, by: string) {
  booking.statusHistory.push({ from, to, at: new Date().toISOString(), by });
}

// ── Auto-Dispatch Engine ─────────────────────────────────────────────────────
function autoDispatchBooking(bookingId: string) {
  const booking = bookings.get(bookingId);
  if (!booking || booking.status === 'CANCELLED') return;

  // Find online + available partners
  const eligiblePartners: PartnerRecord[] = [];
  for (const [, p] of partners) {
    if (
      p.status === 'ACTIVE' &&
      p.verificationStatus === 'VERIFIED' &&
      p.isOnline &&
      p.isAvailable &&
      p.canAcceptBookings &&
      !booking.declinedBy.includes(p.id)
    ) {
      eligiblePartners.push(p);
    }
  }

  // Update booking to dispatching
  booking.status = 'DISPATCHING';
  booking.dispatchRound = 1;
  recordStatusChange(booking, 'PAID', 'DISPATCHING', 'system');
  emitEvent(`client:${booking.userId}`, 'booking:status-update', {
    bookingId,
    status: 'DISPATCHING',
  });

  if (eligiblePartners.length === 0) {
    // Even with no online partners, set to PARTNER_OFFERED so the client sees progress
    // The partner app will pick it up when a partner goes online
    booking.status = 'PARTNER_OFFERED';
    recordStatusChange(booking, 'DISPATCHING', 'PARTNER_OFFERED', 'system');
    emitEvent(`client:${booking.userId}`, 'booking:status-update', {
      bookingId,
      status: 'PARTNER_OFFERED',
    });
    return;
  }

  booking.status = 'PARTNER_OFFERED';
  recordStatusChange(booking, 'DISPATCHING', 'PARTNER_OFFERED', 'system');

  // Notify all eligible partners
  const pkg = PACKAGES.find(p => p.id === booking.packageId) || PACKAGES[0];
  for (const p of eligiblePartners) {
    const distanceKm = Math.round(Math.random() * 30 + 5) / 10; // Simulated
    emitEvent(`partner:${p.id}`, 'dispatch:new', {
      bookingId,
      packageName: pkg.name,
      clientArea: booking.address,
      distanceKm,
      etaMinutes: Math.ceil((distanceKm / 30) * 60),
      earning: pkg.partnerPayout,
      expiresIn: 45,
      expiresAt: new Date(Date.now() + 45000).toISOString(),
      bookingDate: booking.bookingDate,
      timeSlot: booking.timeSlot,
    });
  }

  emitEvent(`client:${booking.userId}`, 'booking:status-update', {
    bookingId,
    status: 'PARTNER_OFFERED',
  });
}

// ── Route Handler ────────────────────────────────────────────────────────────
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    ensureSeeded();

    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method.toUpperCase();

    // CORS Preflight
    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    // Health
    if (path === '/' || path === '/health' || path === '/api' || path === '/api/health') {
      return json({
        status: 'ok',
        service: 'orbit-stateful-edge',
        message: 'ORBIT Platform API is online (stateful mode)',
        version: '2.0.0',
        environment: env.NODE_ENV || 'production',
        timestamp: new Date().toISOString(),
        stats: {
          users: users.size,
          partners: partners.size,
          bookings: bookings.size,
          events: realtimeEvents.length,
        },
      });
    }

    const p = path.startsWith('/api/') ? path.substring(4) : path;
    let body: any = {};
    if (['POST', 'PUT', 'PATCH'].includes(method)) {
      try { body = await request.json(); } catch (_) {}
    }

    // ══════════════════════════════════════════════════════════════════════════
    // AUTH ENDPOINTS
    // ══════════════════════════════════════════════════════════════════════════

    // POST /auth/register
    if (p === '/auth/register' && method === 'POST') {
      const email = (body.email || '').trim().toLowerCase();
      const name = body.name || email.split('@')[0] || 'Orbit User';
      const role = body.role || 'CLIENT';

      const normalizedEmail = email.includes('@') ? email : `${email.replace(/\s+/g, '')}@orbit-user.com`;

      // Find existing or create
      let user: UserRecord | undefined;
      for (const [, u] of users) {
        if (u.email === normalizedEmail) { user = u; break; }
      }

      if (!user) {
        user = {
          id: genId('user'),
          email: normalizedEmail,
          name,
          role: role as any,
          createdAt: new Date().toISOString(),
        };

        if (role === 'PARTNER') {
          const pid = genId('partner');
          user.partnerId = pid;
          partners.set(pid, {
            id: pid,
            userId: user.id,
            displayName: name,
            status: 'ACTIVE',
            verificationStatus: 'VERIFIED',
            isOnline: false,
            isAvailable: true,
            canAcceptBookings: true,
            rating: 5.0,
            completedProjects: 0,
            activeProjects: 0,
            walletBalance: 0,
            totalEarned: 0,
            monthEarned: 0,
            weekEarned: 0,
          });
        }
        users.set(user.id, user);
      }

      const accessToken = issueToken(user.id);
      const refreshToken = `orbit_refresh_${Date.now()}`;

      const partner = user.partnerId ? partners.get(user.partnerId) : null;

      return json({
        accessToken,
        refreshToken,
        user: { id: user.id, email: user.email, name: user.name, role: user.role },
        ...(partner ? {
          partner: {
            id: partner.id,
            status: partner.status,
            displayName: partner.displayName,
            rating: partner.rating,
            completedProjects: partner.completedProjects,
            activeProjects: partner.activeProjects,
            walletBalance: partner.walletBalance,
          },
        } : {}),
      }, 201);
    }

    // POST /auth/login
    if (p === '/auth/login' && method === 'POST') {
      const email = (body.email || '').trim().toLowerCase();
      const normalizedEmail = email.includes('@') ? email : `${email.replace(/\s+/g, '')}@orbit-user.com`;

      let user: UserRecord | undefined;
      for (const [, u] of users) {
        if (u.email === normalizedEmail) { user = u; break; }
      }

      if (!user) {
        // Auto-create for frictionless onboarding
        user = {
          id: genId('user'),
          email: normalizedEmail,
          name: email.split('@')[0] || 'Orbit User',
          role: 'CLIENT',
          createdAt: new Date().toISOString(),
        };
        users.set(user.id, user);
      }

      const accessToken = issueToken(user.id);
      const refreshToken = `orbit_refresh_${Date.now()}`;
      const partner = user.partnerId ? partners.get(user.partnerId) : null;

      return json({
        accessToken,
        refreshToken,
        user: { id: user.id, email: user.email, name: user.name, role: user.role },
        ...(partner ? {
          partner: {
            id: partner.id,
            status: partner.status,
            displayName: partner.displayName,
            rating: partner.rating,
            completedProjects: partner.completedProjects,
          },
        } : {}),
      });
    }

    // POST /auth/oauth (Google/Apple)
    if (p === '/auth/oauth' && method === 'POST') {
      const email = (body.email || '').trim().toLowerCase();
      const name = body.name || email.split('@')[0] || 'Orbit User';
      const role = body.role || 'CLIENT';

      let user: UserRecord | undefined;
      for (const [, u] of users) {
        if (u.email === email) { user = u; break; }
      }

      if (!user) {
        user = {
          id: genId('user'),
          email,
          name,
          role: role as any,
          avatar: body.avatar,
          createdAt: new Date().toISOString(),
        };
        if (role === 'PARTNER') {
          const pid = genId('partner');
          user.partnerId = pid;
          partners.set(pid, {
            id: pid,
            userId: user.id,
            displayName: name,
            status: 'ACTIVE',
            verificationStatus: 'VERIFIED',
            isOnline: false,
            isAvailable: true,
            canAcceptBookings: true,
            rating: 5.0,
            completedProjects: 0,
            activeProjects: 0,
            walletBalance: 0,
            totalEarned: 0,
            monthEarned: 0,
            weekEarned: 0,
          });
        }
        users.set(user.id, user);
      }

      const accessToken = issueToken(user.id);
      const refreshToken = `orbit_refresh_${Date.now()}`;
      const partner = user.partnerId ? partners.get(user.partnerId) : null;

      return json({
        accessToken,
        refreshToken,
        user: { id: user.id, email: user.email, name: user.name, role: user.role },
        ...(partner ? {
          partner: {
            id: partner.id,
            status: partner.status,
            displayName: partner.displayName,
            rating: partner.rating,
            completedProjects: partner.completedProjects,
          },
        } : {}),
      });
    }

    // POST /auth/send-otp
    if (p === '/auth/send-otp') {
      return json({ success: true, message: 'Verification code sent (Demo code: 123456)' });
    }

    // POST /auth/verify-otp
    if (p === '/auth/verify-otp' && method === 'POST') {
      const email = (body.email || 'user@orbit.app').trim().toLowerCase();
      const role = body.role || 'CLIENT';
      const name = body.name || email.split('@')[0];

      let user: UserRecord | undefined;
      for (const [, u] of users) {
        if (u.email === email) { user = u; break; }
      }

      if (!user) {
        user = {
          id: genId('user'),
          email,
          name,
          role: role as any,
          createdAt: new Date().toISOString(),
        };
        if (role === 'PARTNER') {
          const pid = genId('partner');
          user.partnerId = pid;
          partners.set(pid, {
            id: pid,
            userId: user.id,
            displayName: name,
            status: 'ACTIVE',
            verificationStatus: 'VERIFIED',
            isOnline: false,
            isAvailable: true,
            canAcceptBookings: true,
            rating: 5.0,
            completedProjects: 0,
            activeProjects: 0,
            walletBalance: 0,
            totalEarned: 0,
            monthEarned: 0,
            weekEarned: 0,
          });
        }
        users.set(user.id, user);
      }

      const accessToken = issueToken(user.id);
      const refreshToken = `orbit_refresh_${Date.now()}`;
      const partner = user.partnerId ? partners.get(user.partnerId) : null;

      return json({
        success: true,
        accessToken,
        refreshToken,
        user: { id: user.id, email: user.email, name: user.name, role: user.role },
        partner: partner ? {
          id: partner.id,
          status: partner.status,
          displayName: partner.displayName,
          rating: partner.rating,
          completedProjects: partner.completedProjects,
          activeProjects: partner.activeProjects,
          walletBalance: partner.walletBalance,
        } : null,
      });
    }

    // POST /auth/refresh
    if (p === '/auth/refresh' && method === 'POST') {
      // For demo, issue a new token for the first user
      const firstUser = users.values().next().value;
      if (firstUser) {
        const accessToken = issueToken(firstUser.id);
        return json({ accessToken, refreshToken: `orbit_refresh_${Date.now()}` });
      }
      return json({ error: 'No session found' }, 401);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // PACKAGES
    // ══════════════════════════════════════════════════════════════════════════
    if (p === '/packages') {
      return json(PACKAGES);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // PARTNER ENDPOINTS
    // ══════════════════════════════════════════════════════════════════════════

    // GET /partner/profile
    if (p === '/partner/profile' && method === 'GET') {
      const user = getUserFromRequest(request);
      let partner: PartnerRecord | null = null;

      if (user?.partnerId) {
        partner = partners.get(user.partnerId) || null;
      }

      if (!partner) {
        // Fallback: return first partner
        partner = partners.values().next().value || null;
      }

      if (!partner) return json({ error: 'Partner not found' }, 404);

      const partnerUser = users.get(partner.userId);
      return json({
        ...partner,
        user: partnerUser ? { name: partnerUser.name, email: partnerUser.email } : null,
      });
    }

    // PUT /partner/profile
    if (p === '/partner/profile' && method === 'PUT') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : null;
      if (!partner) return json({ error: 'Partner not found' }, 404);

      if (body.displayName) partner.displayName = body.displayName;
      if (body.fcmToken) partner.fcmToken = body.fcmToken;

      return json(partner);
    }

    // PATCH /partner/status — Toggle online/offline
    if (p === '/partner/status' && method === 'PATCH') {
      const user = getUserFromRequest(request);
      let partner: PartnerRecord | null = null;

      if (user?.partnerId) {
        partner = partners.get(user.partnerId) || null;
      }

      if (!partner) {
        // Fallback for testing
        partner = partners.values().next().value || null;
      }

      if (!partner) return json({ error: 'Partner not found' }, 404);

      const isOnline = body.isOnline ?? !partner.isOnline;
      partner.isOnline = isOnline;
      partner.isAvailable = isOnline;
      partner.lastSeenAt = new Date().toISOString();

      if (body.latitude !== undefined) partner.latitude = body.latitude;
      if (body.longitude !== undefined) partner.longitude = body.longitude;

      // When partner goes online, check for any PARTNER_OFFERED bookings waiting
      if (isOnline) {
        for (const [, bk] of bookings) {
          if (bk.status === 'PARTNER_OFFERED' && !bk.partnerId && !bk.declinedBy.includes(partner.id)) {
            const pkg = PACKAGES.find(pk => pk.id === bk.packageId) || PACKAGES[0];
            emitEvent(`partner:${partner.id}`, 'dispatch:new', {
              bookingId: bk.id,
              packageName: pkg.name,
              clientArea: bk.address,
              distanceKm: 2.1,
              etaMinutes: 8,
              earning: pkg.partnerPayout,
              expiresIn: 45,
              expiresAt: new Date(Date.now() + 45000).toISOString(),
              bookingDate: bk.bookingDate,
              timeSlot: bk.timeSlot,
            });
          }
        }
      }

      return json({ success: true, isOnline });
    }

    // POST /partner/online
    if (p === '/partner/online' && method === 'POST') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : partners.values().next().value;
      if (!partner) return json({ error: 'Partner not found' }, 404);

      partner.isOnline = true;
      partner.isAvailable = true;
      if (body.latitude) partner.latitude = body.latitude;
      if (body.longitude) partner.longitude = body.longitude;
      partner.lastSeenAt = new Date().toISOString();

      return json({ success: true, message: 'You are now online and accepting bookings' });
    }

    // POST /partner/offline
    if (p === '/partner/offline' && method === 'POST') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : partners.values().next().value;
      if (!partner) return json({ error: 'Partner not found' }, 404);

      partner.isOnline = false;
      partner.isAvailable = false;

      return json({ success: true, message: 'You are now offline' });
    }

    // GET /partner/available-jobs
    if (p === '/partner/available-jobs' && method === 'GET') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : null;
      const partnerId = partner?.id;

      // Find active job for this partner
      let activeJob: any = null;
      const pendingOffers: any[] = [];

      for (const [, bk] of bookings) {
        if (partnerId && bk.partnerId === partnerId &&
            ['PARTNER_ASSIGNED', 'EN_ROUTE', 'ARRIVED', 'SHOOTING', 'UPLOADING'].includes(bk.status)) {
          const pkg = PACKAGES.find(pk => pk.id === bk.packageId) || PACKAGES[0];
          activeJob = {
            bookingId: bk.id,
            status: bk.status,
            packageName: pkg.name,
            clientArea: bk.address,
            earning: pkg.partnerPayout,
            latitude: bk.latitude,
            longitude: bk.longitude,
          };
        }

        if (bk.status === 'PARTNER_OFFERED' && !bk.partnerId &&
            !(partnerId && bk.declinedBy.includes(partnerId))) {
          const pkg = PACKAGES.find(pk => pk.id === bk.packageId) || PACKAGES[0];
          pendingOffers.push({
            bookingId: bk.id,
            packageName: pkg.name,
            clientArea: bk.address,
            earning: pkg.partnerPayout,
            bookingDate: bk.bookingDate,
            timeSlot: bk.timeSlot,
          });
        }
      }

      return json({ activeJob, pendingOffers, todayTarget: 5, bonusAmount: 300 });
    }

    // GET /partner/earnings/summary
    if (p === '/partner/earnings/summary' && method === 'GET') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : partners.values().next().value;

      if (!partner) {
        return json({
          totalEarned: 0, monthEarned: 0, weekEarned: 0,
          todayEarnings: 0, completedToday: 0, completedCount: 0, rating: 5.0,
        });
      }

      return json({
        totalEarned: partner.totalEarned,
        monthEarned: partner.monthEarned,
        weekEarned: partner.weekEarned,
        todayEarnings: partner.weekEarned > 0 ? Math.round(partner.weekEarned / 7) : 0,
        completedToday: Math.min(partner.completedProjects, 3),
        completedCount: partner.completedProjects,
        rating: partner.rating,
      });
    }

    // GET /partner/earnings
    if (p === '/partner/earnings' && method === 'GET') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : partners.values().next().value;

      return json({
        totalEarned: partner?.totalEarned || 8400,
        monthEarned: partner?.monthEarned || 2800,
        weekEarned: partner?.weekEarned || 1400,
        completedCount: partner?.completedProjects || 12,
        rating: partner?.rating || 5.0,
      });
    }

    // GET /partner/history
    if (p === '/partner/history' && method === 'GET') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : null;

      const history: any[] = [];
      for (const [, bk] of bookings) {
        if (partner && bk.partnerId === partner.id && ['DELIVERED', 'CANCELLED'].includes(bk.status)) {
          const pkg = PACKAGES.find(pk => pk.id === bk.packageId) || PACKAGES[0];
          history.push({
            id: bk.id,
            status: bk.status,
            packageName: pkg.name,
            address: bk.address,
            earning: pkg.partnerPayout,
            createdAt: bk.createdAt,
          });
        }
      }

      return json({ history, total: history.length });
    }

    // GET /partner/dispatches/pending
    if (p === '/partner/dispatches/pending' && method === 'GET') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : null;

      const dispatches: any[] = [];
      for (const [, bk] of bookings) {
        if (bk.status === 'PARTNER_OFFERED' && !bk.partnerId) {
          const pkg = PACKAGES.find(pk => pk.id === bk.packageId) || PACKAGES[0];
          dispatches.push({
            id: genId('disp'),
            bookingId: bk.id,
            status: 'PENDING',
            booking: {
              id: bk.id,
              address: bk.address,
              bookingDate: bk.bookingDate,
              timeSlot: bk.timeSlot,
              package: pkg,
            },
          });
        }
      }

      return json(dispatches);
    }

    // POST /partner/verify-code
    if (p === '/partner/verify-code' && method === 'POST') {
      return json({ success: true, message: 'Partner verified', status: 'ACTIVE' });
    }

    // ══════════════════════════════════════════════════════════════════════════
    // BOOKING ENDPOINTS
    // ══════════════════════════════════════════════════════════════════════════

    // GET /bookings — List bookings
    if (p === '/bookings' && method === 'GET') {
      const user = getUserFromRequest(request);
      const result: any[] = [];

      for (const [, bk] of bookings) {
        let match = false;
        if (user?.role === 'CLIENT' && bk.userId === user.id) match = true;
        if (user?.role === 'PARTNER' && user.partnerId && bk.partnerId === user.partnerId) match = true;
        if (!user) match = true; // Show all if no auth

        if (match) {
          const pkg = PACKAGES.find(pk => pk.id === bk.packageId) || PACKAGES[0];
          const assignedPartner = bk.partnerId ? partners.get(bk.partnerId) : null;
          result.push({
            ...bk,
            package: pkg,
            partner: assignedPartner ? {
              id: assignedPartner.id,
              displayName: assignedPartner.displayName,
              rating: assignedPartner.rating,
              user: { name: assignedPartner.displayName },
            } : null,
          });
        }
      }

      return json({ bookings: result, total: result.length, page: 1, pages: 1 });
    }

    // POST /bookings — Create booking (Client)
    if (p === '/bookings' && method === 'POST') {
      const user = getUserFromRequest(request);
      const userId = user?.id || genId('user');

      const packageId = body.packageId || 'pkg_standard';
      const pkg = PACKAGES.find(pk => pk.id === packageId) || PACKAGES[0];

      const bookingId = genId('bk');
      const booking: BookingRecord = {
        id: bookingId,
        userId,
        packageId: pkg.id,
        status: 'PAID',
        paymentStatus: 'SUCCESS',
        latitude: body.latitude || 18.5596,
        longitude: body.longitude || 73.7857,
        address: body.address || 'Selected Location',
        bookingDate: body.bookingDate || new Date().toISOString(),
        timeSlot: body.timeSlot || 'Now',
        notes: body.notes,
        createdAt: new Date().toISOString(),
        dispatchRound: 0,
        declinedBy: [],
        statusHistory: [{ from: null, to: 'PAID', at: new Date().toISOString(), by: userId }],
      };

      bookings.set(bookingId, booking);

      // Trigger auto-dispatch asynchronously
      autoDispatchBooking(bookingId);

      return json({
        booking: {
          ...booking,
          package: pkg,
        },
        payment: {
          orderId: `order_${Date.now()}`,
          paymentId: `pay_orbit_${Date.now()}`,
          amount: pkg.price,
          currency: 'INR',
          status: 'PAID',
        },
      }, 201);
    }

    // GET /bookings/:id — Single booking
    const bookingGetMatch = p.match(/^\/bookings\/([^/]+)$/);
    if (bookingGetMatch && method === 'GET') {
      const bkId = bookingGetMatch[1];
      const bk = bookings.get(bkId);

      if (!bk) return json({ error: 'Booking not found' }, 404);

      const pkg = PACKAGES.find(pk => pk.id === bk.packageId) || PACKAGES[0];
      const assignedPartner = bk.partnerId ? partners.get(bk.partnerId) : null;

      return json({
        ...bk,
        package: pkg,
        partner: assignedPartner ? {
          id: assignedPartner.id,
          displayName: assignedPartner.displayName,
          rating: assignedPartner.rating,
          latitude: assignedPartner.latitude,
          longitude: assignedPartner.longitude,
          user: { name: assignedPartner.displayName, email: users.get(assignedPartner.userId)?.email },
        } : null,
        statusHistory: bk.statusHistory,
        mediaAssets: [],
      });
    }

    // POST /bookings/:id/accept — Partner accepts
    const acceptMatch = p.match(/^\/bookings\/([^/]+)\/accept$/);
    if (acceptMatch && method === 'POST') {
      const bkId = acceptMatch[1];
      const bk = bookings.get(bkId);
      if (!bk) return json({ error: 'Booking not found' }, 404);

      if (!['DISPATCHING', 'PARTNER_OFFERED'].includes(bk.status)) {
        return json({ success: false, message: 'Booking no longer available' }, 409);
      }

      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : partners.values().next().value;
      if (!partner) return json({ error: 'Partner not found' }, 404);

      // Assign partner
      bk.partnerId = partner.id;
      bk.status = 'PARTNER_ASSIGNED';
      bk.partnerAssignedAt = new Date().toISOString();
      partner.isAvailable = false;
      partner.activeProjects += 1;

      recordStatusChange(bk, 'PARTNER_OFFERED', 'PARTNER_ASSIGNED', partner.id);

      // Notify client
      emitEvent(`client:${bk.userId}`, 'booking:status-update', {
        bookingId: bk.id,
        status: 'PARTNER_ASSIGNED',
        partner: {
          id: partner.id,
          displayName: partner.displayName,
          rating: partner.rating,
        },
      });

      // Notify booking room
      emitEvent(`booking:${bk.id}`, 'dispatch:accepted', {
        bookingId: bk.id,
        partnerId: partner.id,
      });

      return json({ success: true, message: 'Booking accepted successfully' });
    }

    // POST /bookings/:id/decline — Partner declines
    const declineMatch = p.match(/^\/bookings\/([^/]+)\/decline$/);
    if (declineMatch && method === 'POST') {
      const bkId = declineMatch[1];
      const bk = bookings.get(bkId);
      if (!bk) return json({ error: 'Booking not found' }, 404);

      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : null;
      if (partner) {
        bk.declinedBy.push(partner.id);
      }

      return json({ success: true });
    }

    // POST /bookings/:id/en-route
    const enrouteMatch = p.match(/^\/bookings\/([^/]+)\/en-route$/);
    if (enrouteMatch && method === 'POST') {
      const bkId = enrouteMatch[1];
      const bk = bookings.get(bkId);
      if (!bk) return json({ error: 'Booking not found' }, 404);

      if (bk.status !== 'PARTNER_ASSIGNED') {
        return json({ error: 'Invalid state for en-route. Must be PARTNER_ASSIGNED.' }, 400);
      }

      bk.status = 'EN_ROUTE';
      recordStatusChange(bk, 'PARTNER_ASSIGNED', 'EN_ROUTE', bk.partnerId || 'partner');

      emitEvent(`client:${bk.userId}`, 'booking:status-update', { bookingId: bk.id, status: 'EN_ROUTE' });
      emitEvent(`booking:${bk.id}`, 'booking:status-update', { bookingId: bk.id, status: 'EN_ROUTE' });

      return json({ success: true });
    }

    // POST /bookings/:id/arrived
    const arrivedMatch = p.match(/^\/bookings\/([^/]+)\/arrived$/);
    if (arrivedMatch && method === 'POST') {
      const bkId = arrivedMatch[1];
      const bk = bookings.get(bkId);
      if (!bk) return json({ error: 'Booking not found' }, 404);

      if (bk.status !== 'EN_ROUTE') {
        return json({ error: 'Invalid state for arrival' }, 400);
      }

      bk.status = 'ARRIVED';
      bk.arrivedAt = new Date().toISOString();
      recordStatusChange(bk, 'EN_ROUTE', 'ARRIVED', bk.partnerId || 'partner');

      emitEvent(`client:${bk.userId}`, 'booking:status-update', { bookingId: bk.id, status: 'ARRIVED' });
      emitEvent(`booking:${bk.id}`, 'partner:arrived', { bookingId: bk.id });

      return json({ success: true });
    }

    // POST /bookings/:id/start-shoot
    const startShootMatch = p.match(/^\/bookings\/([^/]+)\/start-shoot$/);
    if (startShootMatch && method === 'POST') {
      const bkId = startShootMatch[1];
      const bk = bookings.get(bkId);
      if (!bk) return json({ error: 'Booking not found' }, 404);

      if (bk.status !== 'ARRIVED') {
        return json({ error: 'Partner must arrive before starting shoot' }, 400);
      }

      bk.status = 'SHOOTING';
      bk.shootingStartedAt = new Date().toISOString();
      recordStatusChange(bk, 'ARRIVED', 'SHOOTING', bk.partnerId || 'partner');

      emitEvent(`client:${bk.userId}`, 'booking:status-update', { bookingId: bk.id, status: 'SHOOTING' });
      emitEvent(`booking:${bk.id}`, 'shooting:started', { bookingId: bk.id });

      return json({ success: true });
    }

    // POST /bookings/:id/complete-shoot
    const completeShootMatch = p.match(/^\/bookings\/([^/]+)\/complete-shoot$/);
    if (completeShootMatch && method === 'POST') {
      const bkId = completeShootMatch[1];
      const bk = bookings.get(bkId);
      if (!bk) return json({ error: 'Booking not found' }, 404);

      if (bk.status !== 'SHOOTING') {
        return json({ error: 'Shooting must be in progress' }, 400);
      }

      bk.status = 'UPLOADING';
      bk.shootingEndedAt = new Date().toISOString();
      recordStatusChange(bk, 'SHOOTING', 'UPLOADING', bk.partnerId || 'partner');

      // Update partner stats
      if (bk.partnerId) {
        const partner = partners.get(bk.partnerId);
        if (partner) {
          const pkg = PACKAGES.find(pk => pk.id === bk.packageId) || PACKAGES[0];
          partner.isAvailable = true;
          partner.activeProjects = Math.max(0, partner.activeProjects - 1);
          partner.completedProjects += 1;
          partner.walletBalance += pkg.partnerPayout;
          partner.totalEarned += pkg.partnerPayout;
          partner.monthEarned += pkg.partnerPayout;
          partner.weekEarned += pkg.partnerPayout;
        }
      }

      emitEvent(`client:${bk.userId}`, 'booking:status-update', { bookingId: bk.id, status: 'UPLOADING' });
      emitEvent(`booking:${bk.id}`, 'shooting:completed', { bookingId: bk.id });

      return json({ success: true });
    }

    // POST /bookings/:id/confirm-payment
    const confirmPayMatch = p.match(/^\/bookings\/([^/]+)\/confirm-payment$/);
    if (confirmPayMatch && method === 'POST') {
      const bkId = confirmPayMatch[1];
      const bk = bookings.get(bkId);
      if (!bk) return json({ error: 'Booking not found' }, 404);

      bk.status = 'PAID';
      bk.paymentStatus = 'SUCCESS';
      recordStatusChange(bk, bk.status, 'PAID', bk.userId);

      // Trigger dispatch
      autoDispatchBooking(bkId);

      return json({ success: true, bookingId: bkId, status: 'PAID' });
    }

    // POST /bookings/:id/cancel
    const cancelMatch = p.match(/^\/bookings\/([^/]+)\/cancel$/);
    if (cancelMatch && method === 'POST') {
      const bkId = cancelMatch[1];
      const bk = bookings.get(bkId);
      if (!bk) return json({ error: 'Booking not found' }, 404);

      const NOT_CANCELLABLE = ['SHOOTING', 'UPLOADING', 'DELIVERED'];
      if (NOT_CANCELLABLE.includes(bk.status)) {
        return json({ canCancel: false, error: 'Cancellation not available at this stage' }, 400);
      }

      bk.status = 'CANCELLED';
      bk.cancelledAt = new Date().toISOString();
      bk.cancelledBy = body.role || 'CLIENT';
      bk.cancellationReason = body.reason || '';

      // Release partner
      if (bk.partnerId) {
        const partner = partners.get(bk.partnerId);
        if (partner) {
          partner.isAvailable = true;
          partner.activeProjects = Math.max(0, partner.activeProjects - 1);
        }
        emitEvent(`partner:${bk.partnerId}`, 'booking:status-update', { bookingId: bk.id, status: 'CANCELLED' });
      }

      emitEvent(`client:${bk.userId}`, 'booking:status-update', { bookingId: bk.id, status: 'CANCELLED' });

      return json({ success: true, canCancel: true, cancellationFee: 0 });
    }

    // ══════════════════════════════════════════════════════════════════════════
    // REAL-TIME EVENT POLLING (replaces Socket.IO + Firestore)
    // ══════════════════════════════════════════════════════════════════════════

    // GET /events/poll?channel=client:userId&since=timestamp
    if (p === '/events/poll' && method === 'GET') {
      const channel = url.searchParams.get('channel') || '';
      const since = url.searchParams.get('since') || '2000-01-01T00:00:00.000Z';

      const events = realtimeEvents.filter(e =>
        e.channel === channel && e.createdAt > since
      );

      return json({ events, serverTime: new Date().toISOString() });
    }

    // GET /events/poll/booking/:id?since=timestamp
    const eventBookingMatch = p.match(/^\/events\/poll\/booking\/([^/]+)$/);
    if (eventBookingMatch && method === 'GET') {
      const bookingId = eventBookingMatch[1];
      const since = url.searchParams.get('since') || '2000-01-01T00:00:00.000Z';

      const events = realtimeEvents.filter(e =>
        e.channel === `booking:${bookingId}` && e.createdAt > since
      );

      // Also include client events for this booking's user
      const bk = bookings.get(bookingId);
      if (bk) {
        const clientEvents = realtimeEvents.filter(e =>
          e.channel === `client:${bk.userId}` &&
          e.createdAt > since &&
          e.payload?.bookingId === bookingId
        );
        events.push(...clientEvents);
      }

      return json({ events, serverTime: new Date().toISOString() });
    }

    // GET /events/poll/partner/:id?since=timestamp
    const eventPartnerMatch = p.match(/^\/events\/poll\/partner\/([^/]+)$/);
    if (eventPartnerMatch && method === 'GET') {
      const partnerId = eventPartnerMatch[1];
      const since = url.searchParams.get('since') || '2000-01-01T00:00:00.000Z';

      const events = realtimeEvents.filter(e =>
        e.channel === `partner:${partnerId}` && e.createdAt > since
      );

      return json({ events, serverTime: new Date().toISOString() });
    }

    // ══════════════════════════════════════════════════════════════════════════
    // LOCATION
    // ══════════════════════════════════════════════════════════════════════════

    // POST /location/update
    if ((p === '/location/update' || p === '/maps/location') && method === 'POST') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : null;

      if (partner && body.latitude !== undefined && body.longitude !== undefined) {
        partner.latitude = body.latitude;
        partner.longitude = body.longitude;
        partner.lastSeenAt = new Date().toISOString();
      }

      return json({ success: true });
    }

    // ══════════════════════════════════════════════════════════════════════════
    // NOTIFICATIONS
    // ══════════════════════════════════════════════════════════════════════════
    if (p === '/notifications' && method === 'GET') {
      return json([
        {
          id: 'n1',
          title: 'Welcome to ORBIT',
          body: 'Book your first professional shoot in seconds.',
          isRead: false,
          createdAt: new Date().toISOString(),
        },
      ]);
    }

    if (p.match(/^\/notifications\/[^/]+\/read$/) && method === 'PATCH') {
      return json({ success: true });
    }

    if (p === '/notifications/read-all' && method === 'PATCH') {
      return json({ success: true });
    }

    // ══════════════════════════════════════════════════════════════════════════
    // WALLET
    // ══════════════════════════════════════════════════════════════════════════
    if (p === '/wallet/balance' && method === 'GET') {
      const user = getUserFromRequest(request);
      const partner = user ? getPartnerForUser(user.id) : partners.values().next().value;
      return json({
        available: partner?.walletBalance || 0,
        reserved: 0,
        totalEarned: partner?.totalEarned || 0,
        totalWithdrawn: 0,
      });
    }

    // 404 fallback
    return json({ error: 'Route not found', path: p, method }, 404);
  },
};
