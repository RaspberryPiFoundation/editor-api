(function () {
  var project = document.getElementById("editor-app-project");

  if (!project) {
    return;
  }

  function projectPath(identifier) {
    return project.dataset.projectsPath + "/" + identifier;
  }

  // A remix is saved under a new identifier. Replacing the URL in place keeps
  // the editor and any unsaved work mounted, which navigating would not.
  document.addEventListener("editor-projectIdentifierChanged", function (event) {
    if (event.detail) {
      window.history.replaceState({}, "", projectPath(event.detail));
    }
  });

  document.addEventListener("editor-navigateToProjectsPage", function () {
    window.location.assign(project.dataset.projectsPath);
  });

  document.addEventListener("editor-projectLoadFailed", function () {
    window.location.assign(project.dataset.errorPath);
  });

  document.addEventListener("editor-logIn", function () {
    var login = document.getElementById("editor-app-project-login");

    if (login) {
      login.submit();
    }
  });
})();
