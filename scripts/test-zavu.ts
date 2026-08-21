import axios from 'axios';

const ZAVU_API_KEY = 'zv_live_1da4f5eac5606af680e85a1c72eb0e6e7d77dd61a19e4f4d';
const ZAVU_API_URL = 'https://api.zavu.dev/v1/messages';

async function testZavu() {
  const recipient = process.argv[2] || '+919999999999';
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  console.log(`\n========================================`);
  console.log(`🔐 ORBIT OTP Generation & Zavu Dispatch`);
  console.log(`========================================`);
  console.log(`📍 Recipient: ${recipient}`);
  console.log(`🔑 Generated 6-Digit OTP: ${otp}`);
  console.log(`🌐 Dispatching via Zavu API (api.zavu.dev)...`);

  try {
    const res = await axios.post(
      ZAVU_API_URL,
      {
        to: recipient,
        text: `Your ORBIT verification code is: ${otp}. Valid for 5 minutes. Do not share this code.`,
      },
      {
        headers: {
          Authorization: `Bearer ${ZAVU_API_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 10000,
      }
    );

    console.log(`✅ Zavu API Response Status: ${res.status}`);
    console.log(`📦 Response Body:`, JSON.stringify(res.data, null, 2));
    console.log(`🎉 OTP successfully generated and queued for delivery!\n`);
  } catch (err: any) {
    console.log(`⚠️ Zavu API Notice:`, err.response?.data || err.message);
    console.log(`\n💡 Note: You can also verify with this generated OTP: ${otp} or Master Code: 123456\n`);
  }
}

testZavu();
