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

  // Flutter CanvasKit renders into a canvas and exposes an flt-semantics overlay —
  // there are no <input> elements. TextFormField → role="textbox", Button → role="button".

  // Wait for the login form: Sign In button presence confirms Flutter booted and rendered
  await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible({ timeout: 45000 });

  // Fill credentials via the semantic textbox role Flutter exposes for each TextFormField
  await page.getByRole('textbox', { name: 'Username' }).fill(USERNAME);
  await page.getByRole('textbox', { name: 'Password' }).fill(PASSWORD);

  await page.getByRole('button', { name: 'Sign In' }).click();

  // Positive assertion: the Logout destination only appears in MainScreen's NavigationBar
  await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible({ timeout: 20000 });
});
