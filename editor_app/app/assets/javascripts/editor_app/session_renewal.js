(function () {
  var RENEWAL_MARGIN_MS = 120000;
  var MINIMUM_DELAY_MS = 1000;

  if (window.parent !== window) {
    return;
  }

  var session = document.getElementById("editor-app-auth-user");

  if (!session || !session.dataset.expiresAt) {
    return;
  }

  var frame = null;

  function renew() {
    frame = document.createElement("iframe");
    frame.hidden = true;
    frame.title = "";
    frame.src = session.dataset.renewalUrl;
    document.body.appendChild(frame);
  }

  function scheduleRenewal(expiresAt) {
    var delay = expiresAt * 1000 - Date.now() - RENEWAL_MARGIN_MS;
    window.setTimeout(renew, Math.max(delay, MINIMUM_DELAY_MS));
  }

  function announceExpiry() {
    var prompt = document.getElementById("editor-app-session-expired");

    if (prompt) {
      prompt.hidden = false;
    }

    window.dispatchEvent(new CustomEvent("editor-app:session-expired"));
  }

  window.addEventListener("message", function (event) {
    if (event.origin !== window.origin) {
      return;
    }

    if (!event.data || event.data.type !== "editor-app:session-renewal") {
      return;
    }

    if (frame) {
      frame.remove();
      frame = null;
    }

    if (event.data.renewed) {
      scheduleRenewal(event.data.expiresAt);
    } else {
      announceExpiry();
    }
  });

  scheduleRenewal(parseInt(session.dataset.expiresAt, 10));
})();
