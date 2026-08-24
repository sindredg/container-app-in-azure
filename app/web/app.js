// Served as a separate file because the site's Content Security Policy allows
// no inline script. The API is read through the same-origin /api/ proxy, so the
// request never crosses an origin boundary and the internal hostname is never
// exposed to the browser.
(function () {
  "use strict";

  var DETAIL_FIELDS = ["version", "revision", "replica"];
  var PLACEHOLDER = "-";

  // The API scales to zero, so a cold start can take several seconds.
  var TIMEOUT_MS = 15000;

  function setText(id, value) {
    var node = document.getElementById(id);
    if (node) {
      node.textContent = value;
    }
  }

  function setState(label, reachable) {
    var node = document.getElementById("api-state");
    if (node) {
      node.textContent = label;
      node.dataset.state = reachable ? "up" : "down";
    }
  }

  function showFailure(label) {
    setState(label, false);
    DETAIL_FIELDS.forEach(function (field) {
      setText("api-" + field, PLACEHOLDER);
    });
  }

  function showStatus(payload) {
    var healthy = payload.status === "ok";

    setState(healthy ? "reachable" : String(payload.status), healthy);
    DETAIL_FIELDS.forEach(function (field) {
      setText("api-" + field, payload[field] || PLACEHOLDER);
    });
  }

  function load() {
    // Give up rather than leaving the card reading "checking" forever.
    var abort = new AbortController();
    var timer = window.setTimeout(function () {
      abort.abort();
    }, TIMEOUT_MS);

    window
      .fetch("/api/status", {
        headers: { Accept: "application/json" },
        signal: abort.signal,
      })
      .then(function (response) {
        if (!response.ok) {
          throw new Error("HTTP " + response.status);
        }
        return response.json();
      })
      .then(showStatus)
      .catch(function (error) {
        showFailure(error.name === "AbortError" ? "timed out" : "unreachable");
      })
      .then(function () {
        window.clearTimeout(timer);
      });
  }

  load();
})();
