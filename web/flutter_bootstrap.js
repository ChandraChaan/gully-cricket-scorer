{{flutter_js}}
{{flutter_build_config}}

// Flutter's own service worker is deprecated, so the app registers sw.js,
// which keeps a copy of everything for offline use.
_flutter.loader.load();

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('sw.js').catch((error) => {
      console.warn('Offline support is unavailable:', error);
    });
  });
}
