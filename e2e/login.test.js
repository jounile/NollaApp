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

  // Assert the login form is visible — guards against a false pass if the form never rendered
  await expect(page.locator('input[type="password"]')).toBeVisible({ timeout: 45000 });

  await page.getByLabel('Username').fill(USERNAME);
  await page.getByLabel('Password').fill(PASSWORD);

  // Submit — FilledButton with "Sign In" text is exposed as an ARIA button via Flutter semantics
  await page.getByRole('button', { name: 'Sign In' }).click();

  // Positive assertion: MainScreen's bottom nav bar has a Logout destination that only
  // appears after successful login. This fails if login was rejected or navigation didn't happen.
  await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible({ timeout: 20000 });
});
