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

  // Copy the install commands without the trailing comments.
  var copy = document.querySelector(".copy");
  if (copy) {
    copy.addEventListener("click", function () {
      var text = document.querySelector(".code code").textContent
        .split("\n").map(function (l) { return l.replace(/\s+#.*$/, ""); }).join("\n");
      navigator.clipboard.writeText(text).then(function () {
        copy.textContent = "Copied";
        setTimeout(function () { copy.textContent = "Copy"; }, 1600);
      });
    });
  }
})();
