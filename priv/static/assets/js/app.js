// Drift — client-side JavaScript
// Handles theme toggle with localStorage persistence and LiveView hooks.

(function () {
  'use strict';

  // --------------------------------------------------------------------------
  // THEME TOGGLE
  // --------------------------------------------------------------------------

  function getTheme() {
    return localStorage.getItem('drift-theme') || 'light';
  }

  function setTheme(theme) {
    localStorage.setItem('drift-theme', theme);
    document.documentElement.setAttribute('data-theme', theme);
  }

  function toggleTheme() {
    var current = getTheme();
    var next = current === 'dark' ? 'light' : 'dark';
    setTheme(next);
  }

  function initThemeToggle() {
    var btn = document.getElementById('theme-toggle');
    if (!btn) return;

    btn.addEventListener('click', function (e) {
      e.preventDefault();
      toggleTheme();
    });
  }

  // --------------------------------------------------------------------------
  // LiveView HOOK — ScrollTop
  // Scrolls to top of log list on page navigation
  // --------------------------------------------------------------------------

  var ScrollTop = {
    mounted: function () {
      // scroll to top on mount when navigating between pages
      window.scrollTo({ top: 0, behavior: 'instant' });
    },
    updated: function () {
      window.scrollTo({ top: 0, behavior: 'instant' });
    }
  };

  // --------------------------------------------------------------------------
  // INIT
  // --------------------------------------------------------------------------

  document.addEventListener('DOMContentLoaded', function () {
    initThemeToggle();
  });

  // Expose hooks for LiveView
  if (typeof window !== 'undefined') {
    window.ScrollTop = ScrollTop;
  }
})();
