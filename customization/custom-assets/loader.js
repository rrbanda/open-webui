/*
 * Custom loader.js for Open WebUI
 * Volume-mount this file at: /app/backend/open_webui/static/loader.js
 *
 * This file is loaded by the upstream image without any code changes.
 * Define window.applyTheme() to run custom JS on every theme change.
 */

window.applyTheme = function () {
  // Called by Open WebUI whenever the user switches themes.
  // Access the current theme: document.documentElement.classList
  // Examples: 'dark', 'light', 'oled-dark'

  const isDark = document.documentElement.classList.contains('dark');

  // Example: set a custom CSS variable based on theme
  document.documentElement.style.setProperty(
    '--custom-header-bg',
    isDark ? '#0f172a' : '#f8fafc'
  );

  // Example: update page title with custom branding
  // document.title = 'My Custom AI Platform';
};

// Run once on initial load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', window.applyTheme);
} else {
  window.applyTheme();
}
