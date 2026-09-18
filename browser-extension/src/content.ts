// ASH content script — injects theme-aware styles into pages (opt-in)
(() => {
  const applyTheme = (colors: Record<string, string>) => {
    const root = document.documentElement;
    Object.entries(colors).forEach(([k, v]) => {
      root.style.setProperty(`--ash-${k}`, v);
    });
  };
  chrome.storage.sync.get('ashTheme', (data) => {
    if (data.ashTheme?.colors) applyTheme(data.ashTheme.colors);
  });
  chrome.storage.onChanged.addListener((changes) => {
    if (changes.ashTheme?.newValue?.colors) applyTheme(changes.ashTheme.newValue.colors);
  });
})();
export {};
