// BeanBook landing — small interactions
// Live "Begin" demo on the hero recent-shot card: a fast-forwarded brew
// ticking to 30s, then "Saved." with the ratio · time, then resets.

(function () {
  'use strict';

  // ---- Date eyebrow: live, but in the same shape as the screenshot
  function setDateEyebrow() {
    var el = document.getElementById('card-date');
    if (!el) return;
    var days = ['SUNDAY','MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY'];
    var months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    var d = new Date();
    el.textContent = days[d.getDay()] + ', ' + months[d.getMonth()] + ' ' + d.getDate() + ' · 1 BREW';
  }

  // ---- "Begin" → fast-forwarded 30-second brew → "Saved." → reset
  function wireBrewDemo() {
    var btn = document.getElementById('brew-btn');
    var label = btn && btn.querySelector('.brew-label');
    var arrow = btn && btn.querySelector('.brew-arrow');
    var time = document.getElementById('ratio-time');
    var bar = document.getElementById('ratio-bar-fill');
    var hint = document.getElementById('card-hint');
    if (!btn || !label || !time || !bar) return;

    var busy = false;
    var DURATION_MS = 2400;        // ~30s "brewed" in 2.4s real time
    var TARGET_SECONDS = 30;

    var prefersReduced = window.matchMedia &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    btn.addEventListener('click', function () {
      if (busy) return;
      busy = true;

      btn.classList.remove('is-saved');
      btn.classList.add('is-busy');
      label.textContent = 'Pulling';
      arrow.textContent = '0s';
      if (hint) hint.classList.add('is-faded');

      if (prefersReduced) {
        // Snap straight to saved state
        finish();
        return;
      }

      var started = performance.now();
      function frame(now) {
        var t = Math.min(1, (now - started) / DURATION_MS);
        var seconds = Math.floor(t * TARGET_SECONDS);
        arrow.textContent = seconds + 's';
        time.textContent = seconds.toString().padStart(2, '0') + 'S';
        bar.style.width = (60 + t * 40).toFixed(1) + '%';
        if (t < 1) {
          requestAnimationFrame(frame);
        } else {
          finish();
        }
      }
      requestAnimationFrame(frame);
    });

    function finish() {
      btn.classList.remove('is-busy');
      btn.classList.add('is-saved');
      label.textContent = 'Saved. 1:2.00 · 30s';
      arrow.textContent = '✓';
      time.textContent = '30S';
      bar.style.width = '100%';

      // Reset after a beat
      setTimeout(function () {
        btn.classList.remove('is-saved');
        label.textContent = 'Begin';
        arrow.textContent = '→';
        time.textContent = '30S';
        bar.style.width = '60%';
        if (hint) hint.classList.remove('is-faded');
        busy = false;
      }, 2400);
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    setDateEyebrow();
    wireBrewDemo();
  });
})();
