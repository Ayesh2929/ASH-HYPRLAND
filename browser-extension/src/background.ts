// ASH background service worker — MV3
// Listens for theme changes from the dashboard and applies to the extension popup.
chrome.runtime.onInstalled.addListener(() => {
  console.log('[ASH] extension installed');
});

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'sync' && changes.ashTheme) {
    console.log('[ASH] theme updated', changes.ashTheme.newValue);
  }
});

export {};
