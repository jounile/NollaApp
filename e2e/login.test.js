const { test, expect } = require('@playwright/test');

const BASE_URL = process.env.BASE_URL;
const USERNAME = process.env.TEST_USERNAME;
const PASSWORD = process.env.TEST_PASSWORD;

test('login with test credentials navigates to main screen', async ({ page }) => {
  if (!USERNAME || !PASSWORD) {
    throw new Error('TEST_USERNAME and TEST_PASSWORD secrets must be set in the repository');
  }

  // Append ?flutter.semantics=true so Flutter CanvasKit exposes form inputs as real DOM elements
  await page.goto(`${BASE_URL}?flutter.semantics=true`);

  // Wait for Flutter to boot and the username input to appear (up to 45s for cold GH Pages load)
  await page.waitForSelector('input[type="text"]', { timeout: 45000 });

  await page.getByLabel('Username').fill(USERNAME);
  await page.getByLabel('Password').fill(PASSWORD);

  // Submit — FilledButton with "Sign In" text is exposed as an ARIA button via Flutter semantics
  await page.getByRole('button', { name: 'Sign In' }).click();

  // Successful login routes to MainScreen; the password input leaves the DOM
  await expect(page.locator('input[type="password"]')).toBeHidden({ timeout: 20000 });
});
