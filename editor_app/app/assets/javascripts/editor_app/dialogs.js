(function () {
  document.addEventListener("click", function (event) {
    var opener = event.target.closest("[data-dialog-open]");

    if (!opener) {
      return;
    }

    var dialog = document.getElementById(opener.dataset.dialogOpen);

    if (dialog) {
      event.preventDefault();
      dialog.showModal();
    }
  });
})();
