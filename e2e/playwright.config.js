const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: '.',
  timeout: 60 * 1000,
  use: {
    headless: true,
    screenshot: 'on',
    video: 'off',
  },
  outputDir: 'test-results',
});
