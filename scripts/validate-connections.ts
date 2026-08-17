import http from 'http';
import https from 'https';

const BACKEND_URL = process.env.API_URL || 'http://localhost:5000/health';

console.log('🔍 Starting ORBIT System Health & Connection Validator...\n');

async function checkEndpoint(name: string, url: string): Promise<boolean> {
  return new Promise((resolve) => {
    const client = url.startsWith('https') ? https : http;
    const req = client.get(url, (res) => {
      if (res.statusCode && res.statusCode < 400) {
        console.log(`✅ [${name}] Connection successful (${res.statusCode})`);
        resolve(true);
      } else {
        console.log(`⚠️ [${name}] Returned status code: ${res.statusCode}`);
        resolve(false);
      }
    });

    req.on('error', (err) => {
      console.log(`⚠️ [${name}] Offline or unreachable: ${err.message}`);
      resolve(false);
    });

    req.setTimeout(5000, () => {
      req.destroy();
      console.log(`⚠️ [${name}] Connection timed out after 5s`);
      resolve(false);
    });
  });
}

async function runValidation() {
  console.log('1. Checking Backend Health Check Endpoint...');
  await checkEndpoint('Express Backend Health', BACKEND_URL);

  console.log('2. Checking Maps Geocoding Base API...');
  await checkEndpoint('OSRM Geocoding', 'https://nominatim.openstreetmap.org/status.php');

  console.log('\n✨ Validation complete.');
}

runValidation();
