{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const host = document.querySelector("#flutter_host");
    const appRunner = await engineInitializer.initializeEngine({
      hostElement: host || document.body,
    });

    const loader = document.getElementById("loading-indicator");
    if (loader) {
      loader.remove();
    }

    await appRunner.runApp();
  }
});
