import axios from 'axios';

const BASE_URL = process.env.API_URL || 'http://localhost:5000/api';

describe('ORBIT v3.0 Golden Loop E2E Test', () => {
  let clientToken: string;
  let partnerToken: string;
  let editorToken: string;
  let bookingId: string;

  const testEmail = `e2e_client_${Date.now()}@example.com`;
  const partnerEmail = `e2e_partner_${Date.now()}@example.com`;
  const editorEmail = `e2e_editor_${Date.now()}@example.com`;

  test('1. Client Authenticates via OTP', async () => {
    // Send OTP
    const sendRes = await axios.post(`${BASE_URL}/auth/send-otp`, { email: testEmail, role: 'CLIENT' });
    expect(sendRes.status).toBe(200);

    // Verify OTP
    const verifyRes = await axios.post(`${BASE_URL}/auth/verify-otp`, {
      email: testEmail,
      otp: '123456',
      role: 'CLIENT',
    });
    expect(verifyRes.status).toBe(200);
    expect(verifyRes.data.accessToken).toBeDefined();
    clientToken = verifyRes.data.accessToken;
  });

  test('2. Partner Authenticates via OTP', async () => {
    const sendRes = await axios.post(`${BASE_URL}/auth/send-otp`, { email: partnerEmail, role: 'PARTNER' });
    expect(sendRes.status).toBe(200);

    const verifyRes = await axios.post(`${BASE_URL}/auth/verify-otp`, {
      email: partnerEmail,
      otp: '123456',
      role: 'PARTNER',
    });
    expect(verifyRes.status).toBe(200);
    expect(verifyRes.data.accessToken).toBeDefined();
    partnerToken = verifyRes.data.accessToken;
  });

  test('3. Client Fetches Packages & Creates Booking', async () => {
    const pkgRes = await axios.get(`${BASE_URL}/packages`);
    expect(pkgRes.status).toBe(200);
    const packages = Array.isArray(pkgRes.data) ? pkgRes.data : pkgRes.data.packages;
    expect(packages.length).toBeGreaterThan(0);

    const bookRes = await axios.post(
      `${BASE_URL}/bookings`,
      {
        packageId: packages[0].id || 'pkg_creator_personalized',
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Bandra West, Mumbai',
      },
      { headers: { Authorization: `Bearer ${clientToken}` } }
    );
    expect(bookRes.status).toBe(200);
    bookingId = bookRes.data.bookingId || bookRes.data.id || 'bk_demo_e2e';
  });

  test('4. Partner Accepts Shoot Dispatch', async () => {
    const acceptRes = await axios.post(
      `${BASE_URL}/bookings/${bookingId}/accept`,
      {},
      { headers: { Authorization: `Bearer ${partnerToken}` } }
    );
    expect(acceptRes.status).toBe(200);
  });

  test('5. Partner Updates Shoot Lifecycle (En Route -> Arrived -> Completed)', async () => {
    const enRouteRes = await axios.post(
      `${BASE_URL}/bookings/${bookingId}/en-route`,
      {},
      { headers: { Authorization: `Bearer ${partnerToken}` } }
    );
    expect(enRouteRes.status).toBe(200);

    const arrivedRes = await axios.post(
      `${BASE_URL}/bookings/${bookingId}/arrived`,
      {},
      { headers: { Authorization: `Bearer ${partnerToken}` } }
    );
    expect(arrivedRes.status).toBe(200);

    const completeRes = await axios.post(
      `${BASE_URL}/bookings/${bookingId}/complete-shoot`,
      {},
      { headers: { Authorization: `Bearer ${partnerToken}` } }
    );
    expect(completeRes.status).toBe(200);
  });

  test('6. Partner Wallet Verification & Summary', async () => {
    const earningsRes = await axios.get(
      `${BASE_URL}/partner/earnings`,
      { headers: { Authorization: `Bearer ${partnerToken}` } }
    );
    expect(earningsRes.status).toBe(200);
  });
});
