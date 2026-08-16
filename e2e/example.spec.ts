import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  // Replace with the actual URL of the deployed application
  await page.goto('http://localhost:3000');
  
  // Example assertion (adjust based on your app)
  // await expect(page).toHaveTitle(/ORBIT/);
});
