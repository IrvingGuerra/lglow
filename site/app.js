// LGlow landing: reveal on scroll, before/after slider and the copy button.
(function () {
  // Reveal sections as they come into view.
  var items = document.querySelectorAll("[data-reveal]");
  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          e.target.classList.add("in");
          io.unobserve(e.target);
        }
      });
    }, { rootMargin: "0px 0px -8% 0px" });
    items.forEach(function (el) { io.observe(el); });
  } else {
    items.forEach(function (el) { el.classList.add("in"); });
  }

  // Before/after: the range input drives the clip position.
  document.querySelectorAll(".ba").forEach(function (ba) {
    var range = ba.querySelector(".ba-range");
    var set = function () { ba.style.setProperty("--pos", range.value + "%"); };
    range.addEventListener("input", set);
    set();
  });

  // Copy buttons: commands drop their trailing comments, the AI prompt goes as is.
  document.querySelectorAll(".copy").forEach(function (btn) {
    var label = btn.textContent;
    btn.addEventListener("click", function () {
      var text = btn.closest(".code").querySelector("code").textContent;
      if (btn.hasAttribute("data-strip")) {
        text = text.split("\n").map(function (l) { return l.replace(/\s+#.*$/, ""); }).join("\n");
      }
      navigator.clipboard.writeText(text).then(function () {
        btn.textContent = btn.getAttribute("data-done") || "Copied";
        setTimeout(function () { btn.textContent = label; }, 1600);
      });
    });
  });

  // Remember the language the visitor picked.
  document.querySelectorAll("[data-lang]").forEach(function (a) {
    a.addEventListener("click", function () {
      try { localStorage.setItem("lang", a.getAttribute("data-lang")); } catch (e) {}
    });
  });
})();
