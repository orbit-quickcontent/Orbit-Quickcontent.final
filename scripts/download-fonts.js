const fs = require('fs');
const path = require('path');
const https = require('https');

const clientFontsDir = path.join(__dirname, '..', 'client-app', 'assets', 'fonts');
const partnerFontsDir = path.join(__dirname, '..', 'partner-app', 'assets', 'fonts');

fs.mkdirSync(clientFontsDir, { recursive: true });
fs.mkdirSync(partnerFontsDir, { recursive: true });

const fontsToDownload = [
  {
    url: 'https://raw.githubusercontent.com/google/fonts/main/ofl/montserrat/Montserrat%5Bwght%5D.ttf',
    names: ['Montserrat-Regular.ttf', 'Montserrat-SemiBold.ttf', 'Montserrat-Bold.ttf']
  },
  {
    url: 'https://raw.githubusercontent.com/google/fonts/main/ofl/plusjakartasans/PlusJakartaSans%5Bwght%5D.ttf',
    names: ['PlusJakartaSans-Regular.ttf', 'PlusJakartaSans-Medium.ttf', 'PlusJakartaSans-SemiBold.ttf']
  },
  {
    url: 'https://raw.githubusercontent.com/google/fonts/main/ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf',
    names: ['SpaceGrotesk-Regular.ttf', 'SpaceGrotesk-Medium.ttf', 'SpaceGrotesk-SemiBold.ttf']
  }
];

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, (response) => {
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
        return download(response.headers.location, dest).then(resolve).catch(reject);
      }
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(dest, () => {});
      reject(err);
    });
  });
}

async function run() {
  console.log('Downloading fonts...');
  for (const item of fontsToDownload) {
    const primaryName = item.names[0];
    const clientPath = path.join(clientFontsDir, primaryName);
    console.log(`Fetching ${primaryName}...`);
    try {
      await download(item.url, clientPath);
      for (const alias of item.names) {
        const destClient = path.join(clientFontsDir, alias);
        const destPartner = path.join(partnerFontsDir, alias);
        if (destClient !== clientPath) {
          fs.copyFileSync(clientPath, destClient);
        }
        fs.copyFileSync(clientPath, destPartner);
      }
      console.log(`Saved ${item.names.join(', ')}`);
    } catch (e) {
      console.error(`Failed to download ${primaryName}:`, e.message);
    }
  }
  console.log('All fonts downloaded and copied successfully!');
}

run();
