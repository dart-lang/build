/* ENTRYPOINT_EXTENTION_MARKER */
(function() {
var _currentDirectory = (function () {
  var _url;
  var lines = new Error().stack.split('\n');
  function lookupUrl() {
    if (lines.length > 2) {
      var match = lines[1].match(/^\s+at (.+):\d+:\d+$/);
      // Chrome.
      if (match) return match[1];
      // Chrome nested eval case.
      match = lines[1].match(/^\s+at eval [(](.+):\d+:\d+[)]$/);
      if (match) return match[1];
      // Edge.
      match = lines[1].match(/^\s+at.+\((.+):\d+:\d+\)$/);
      if (match) return match[1];
      // Firefox.
      match = lines[0].match(/[<][@](.+):\d+:\d+$/)
      if (match) return match[1];
    }
    // Safari.
    return lines[0].match(/(.+):\d+:\d+$/)[1];
  }
  _url = lookupUrl();
  var lastSlash = _url.lastIndexOf('/');
  if (lastSlash == -1) return _url;
  var currentDirectory = _url.substring(0, lastSlash + 1);
  return currentDirectory;
})();

var baseUrl = (function () {
  // Attempt to detect --precompiled mode for tests, and set the base url
  // appropriately, otherwise set it to '/'.
  var pathParts = location.pathname.split("/");
  if (pathParts[0] == "") {
    pathParts.shift();
  }
  if (pathParts.length > 1 && pathParts[1] == "test") {
    return "/" + pathParts.slice(0, 2).join("/") + "/";
  }
  // Attempt to detect base url using <base href> html tag
  // base href should start and end with "/"
  if (typeof document !== 'undefined') {
    var el = document.getElementsByTagName('base');
    if (el && el[0] && el[0].getAttribute("href") && el[0].getAttribute
    ("href").startsWith("/") && el[0].getAttribute("href").endsWith("/")){
      return el[0].getAttribute("href");
    }
  }
  // return default value
  return "/";
}());

let modulePaths = {
 "dart_sdk": "packages/build_web_compilers/src/dev_compiler/dart_sdk",
 "packages/async/async": "packages/async/async.unsound.ddc",
 "packages/boolean_selector/boolean_selector": "packages/boolean_selector/boolean_selector.unsound.ddc",
 "packages/collection/collection": "packages/collection/collection.unsound.ddc",
 "packages/collection/src/algorithms": "packages/collection/src/algorithms.unsound.ddc",
 "packages/collection/src/canonicalized_map": "packages/collection/src/canonicalized_map.unsound.ddc",
 "packages/collection/src/comparators": "packages/collection/src/comparators.unsound.ddc",
 "packages/collection/src/iterable_zip": "packages/collection/src/iterable_zip.unsound.ddc",
 "packages/collection/src/priority_queue": "packages/collection/src/priority_queue.unsound.ddc",
 "packages/collection/src/utils": "packages/collection/src/utils.unsound.ddc",
 "packages/js/js": "packages/js/js.unsound.ddc",
 "packages/matcher/matcher": "packages/matcher/matcher.unsound.ddc",
 "packages/matcher/src/core_matchers": "packages/matcher/src/core_matchers.unsound.ddc",
 "packages/meta/meta": "packages/meta/meta.unsound.ddc",
 "packages/meta/meta_meta": "packages/meta/meta_meta.unsound.ddc",
 "packages/path/path": "packages/path/path.unsound.ddc",
 "packages/pool/pool": "packages/pool/pool.unsound.ddc",
 "packages/source_map_stack_trace/source_map_stack_trace": "packages/source_map_stack_trace/source_map_stack_trace.unsound.ddc",
 "packages/source_maps/builder": "packages/source_maps/builder.unsound.ddc",
 "packages/source_maps/printer": "packages/source_maps/printer.unsound.ddc",
 "packages/source_maps/refactor": "packages/source_maps/refactor.unsound.ddc",
 "packages/source_maps/source_maps": "packages/source_maps/source_maps.unsound.ddc",
 "packages/source_maps/src/source_map_span": "packages/source_maps/src/source_map_span.unsound.ddc",
 "packages/source_span/source_span": "packages/source_span/source_span.unsound.ddc",
 "packages/stack_trace/src/chain": "packages/stack_trace/src/chain.unsound.ddc",
 "packages/stream_channel/stream_channel": "packages/stream_channel/stream_channel.unsound.ddc",
 "packages/string_scanner/src/charcode": "packages/string_scanner/src/charcode.unsound.ddc",
 "packages/term_glyph/src/generated/ascii_glyph_set": "packages/term_glyph/src/generated/ascii_glyph_set.unsound.ddc",
 "packages/test/bootstrap/browser": "packages/test/bootstrap/browser.unsound.ddc",
 "packages/test/test": "packages/test/test.unsound.ddc",
 "packages/test_api/backend": "packages/test_api/backend.unsound.ddc",
 "packages/test_api/expect": "packages/test_api/expect.unsound.ddc",
 "packages/test_api/hooks": "packages/test_api/hooks.unsound.ddc",
 "packages/test_api/scaffolding": "packages/test_api/scaffolding.unsound.ddc",
 "packages/test_api/src/backend/closed_exception": "packages/test_api/src/backend/closed_exception.unsound.ddc",
 "packages/test_api/src/backend/configuration/on_platform": "packages/test_api/src/backend/configuration/on_platform.unsound.ddc",
 "packages/test_api/src/backend/remote_exception": "packages/test_api/src/backend/remote_exception.unsound.ddc",
 "packages/test_api/src/backend/stack_trace_formatter": "packages/test_api/src/backend/stack_trace_formatter.unsound.ddc",
 "packages/test_api/src/expect/async_matcher": "packages/test_api/src/expect/async_matcher.unsound.ddc",
 "packages/test_api/src/scaffolding/utils": "packages/test_api/src/scaffolding/utils.unsound.ddc",
 "packages/test_api/test_api": "packages/test_api/test_api.unsound.ddc",
 "packages/test_core/scaffolding": "packages/test_core/scaffolding.unsound.ddc",
 "packages/test_core/src/runner/coverage_stub": "packages/test_core/src/runner/coverage_stub.unsound.ddc",
 "packages/test_core/src/runner/plugin/remote_platform_helpers": "packages/test_core/src/runner/plugin/remote_platform_helpers.unsound.ddc",
 "packages/test_core/src/util/os": "packages/test_core/src/util/os.unsound.ddc",
 "packages/test_core/src/util/stack_trace_mapper": "packages/test_core/src/util/stack_trace_mapper.unsound.ddc",
 "packages/test_core/test_core": "packages/test_core/test_core.unsound.ddc",
 "test/disable_sound_null_safety_test": "disable_sound_null_safety_test.unsound.ddc",
 "test/disable_sound_null_safety_test.dart.browser_test": "disable_sound_null_safety_test.dart.browser_test.unsound.ddc"
};
if(!window.$dartLoader) {
   window.$dartLoader = {
     appDigests: _currentDirectory + 'disable_sound_null_safety_test.dart.browser_test.digests',
     moduleIdToUrl: new Map(),
     urlToModuleId: new Map(),
     rootDirectories: new Array(),
     // Used in package:build_runner/src/server/build_updates_client/hot_reload_client.dart
     moduleParentsGraph: new Map(),
     moduleLoadingErrorCallbacks: new Map(),
     forceLoadModule: function (moduleName, callback, onError) {
       // dartdevc only strips the final extension when adding modules to source
       // maps, so we need to do the same.
       if (moduleName.endsWith('.unsound.ddc')) {
         moduleName = moduleName.substring(0, moduleName.length - 12);
       }
       if (typeof onError != 'undefined') {
         var errorCallbacks = $dartLoader.moduleLoadingErrorCallbacks;
         if (!errorCallbacks.has(moduleName)) {
           errorCallbacks.set(moduleName, new Set());
         }
         errorCallbacks.get(moduleName).add(onError);
       }
       requirejs.undef(moduleName);
       requirejs([moduleName], function() {
         if (typeof onError != 'undefined') {
           errorCallbacks.get(moduleName).delete(onError);
         }
         if (typeof callback != 'undefined') {
           callback();
         }
       });
     },
     getModuleLibraries: null, // set up by _initializeTools
   };
}
let customModulePaths = {};
window.$dartLoader.rootDirectories.push(window.location.origin + baseUrl);
for (let moduleName of Object.getOwnPropertyNames(modulePaths)) {
  let modulePath = modulePaths[moduleName];
  if (modulePath != moduleName) {
    customModulePaths[moduleName] = modulePath;
  }
  var src = window.location.origin + '/' + modulePath + '.js';
  if (window.$dartLoader.moduleIdToUrl.has(moduleName)) {
    continue;
  }
  $dartLoader.moduleIdToUrl.set(moduleName, src);
  $dartLoader.urlToModuleId.set(src, moduleName);
}
// Whenever we fail to load a JS module, try to request the corresponding
// `.errors` file, and log it to the console.
(function() {
  var oldOnError = requirejs.onError;
  requirejs.onError = function(e) {
    if (e.requireModules) {
      if (e.message) {
        // If error occurred on loading dependencies, we need to invalidate ancessor too.
        var ancesor = e.message.match(/needed by: (.*)/);
        if (ancesor) {
          e.requireModules.push(ancesor[1]);
        }
      }
      for (const module of e.requireModules) {
        var errorCallbacks = $dartLoader.moduleLoadingErrorCallbacks.get(module);
        if (errorCallbacks) {
          for (const callback of errorCallbacks) callback(e);
          errorCallbacks.clear();
        }
      }
    }
    if (e.originalError && e.originalError.srcElement) {
      var xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function() {
        if (this.readyState == 4) {
          var message;
          if (this.status == 200) {
            message = this.responseText;
          } else {
            message = "Unknown error loading " + e.originalError.srcElement.src;
          }
          console.error(message);
          var errorEvent = new CustomEvent(
            'dartLoadException', { detail: message });
          window.dispatchEvent(errorEvent);
        }
      };
      xhr.open("GET", e.originalError.srcElement.src + ".errors", true);
      xhr.send();
    }
    // Also handle errors the normal way.
    if (oldOnError) oldOnError(e);
  };
}());

var baseUrl = (function () {
  // Attempt to detect --precompiled mode for tests, and set the base url
  // appropriately, otherwise set it to '/'.
  var pathParts = location.pathname.split("/");
  if (pathParts[0] == "") {
    pathParts.shift();
  }
  if (pathParts.length > 1 && pathParts[1] == "test") {
    return "/" + pathParts.slice(0, 2).join("/") + "/";
  }
  // Attempt to detect base url using <base href> html tag
  // base href should start and end with "/"
  if (typeof document !== 'undefined') {
    var el = document.getElementsByTagName('base');
    if (el && el[0] && el[0].getAttribute("href") && el[0].getAttribute
    ("href").startsWith("/") && el[0].getAttribute("href").endsWith("/")){
      return el[0].getAttribute("href");
    }
  }
  // return default value
  return "/";
}());
;

require.config({
    baseUrl: baseUrl,
    waitSeconds: 0,
    paths: customModulePaths
});

const modulesGraph = new Map();
function getRegisteredModuleName(moduleMap) {
  if ($dartLoader.moduleIdToUrl.has(moduleMap.name + '.unsound.ddc')) {
    return moduleMap.name + '.unsound.ddc';
  }
  return moduleMap.name;
}
requirejs.onResourceLoad = function (context, map, depArray) {
  const name = getRegisteredModuleName(map);
  const depNameArray = depArray.map(getRegisteredModuleName);
  if (modulesGraph.has(name)) {
    // TODO Move this logic to better place
    var previousDeps = modulesGraph.get(name);
    var changed = previousDeps.length != depNameArray.length;
    changed = changed || depNameArray.some(function(depName) {
      return !previousDeps.includes(depName);
    });
    if (changed) {
      console.warn("Dependencies graph change for module '" + name + "' detected. " +
        "Dependencies was [" + previousDeps + "], now [" +  depNameArray.map((depName) => depName) +"]. " +
        "Page can't be hot-reloaded, firing full page reload.");
      window.location.reload();
    }
  } else {
    modulesGraph.set(name, []);
    for (const depName of depNameArray) {
      if (!$dartLoader.moduleParentsGraph.has(depName)) {
        $dartLoader.moduleParentsGraph.set(depName, []);
      }
      $dartLoader.moduleParentsGraph.get(depName).push(name);
      modulesGraph.get(name).push(depName);
    }
  }
};
define("disable_sound_null_safety_test.dart.browser_test.dart.bootstrap", ["test/disable_sound_null_safety_test.dart.browser_test", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk.dart.setStartAsyncSynchronously(true);
  dart_sdk.dart.nonNullAsserts(false);
  dart_sdk.dart.nativeNonNullAsserts(true);
  dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
  var baseUrl = (function () {
  // Attempt to detect --precompiled mode for tests, and set the base url
  // appropriately, otherwise set it to '/'.
  var pathParts = location.pathname.split("/");
  if (pathParts[0] == "") {
    pathParts.shift();
  }
  if (pathParts.length > 1 && pathParts[1] == "test") {
    return "/" + pathParts.slice(0, 2).join("/") + "/";
  }
  // Attempt to detect base url using <base href> html tag
  // base href should start and end with "/"
  if (typeof document !== 'undefined') {
    var el = document.getElementsByTagName('base');
    if (el && el[0] && el[0].getAttribute("href") && el[0].getAttribute
    ("href").startsWith("/") && el[0].getAttribute("href").endsWith("/")){
      return el[0].getAttribute("href");
    }
  }
  // return default value
  return "/";
}());

  dart_sdk._debugger.registerDevtoolsFormatter();
  $dartLoader.getModuleLibraries = dart_sdk.dart.getModuleLibraries;
  if (window.$dartStackTraceUtility && !window.$dartStackTraceUtility.ready) {
    window.$dartStackTraceUtility.ready = true;
    let dart = dart_sdk.dart;
    window.$dartStackTraceUtility.setSourceMapProvider(
      function(url) {
        url = url.replace(baseUrl, '/');
        var module = window.$dartLoader.urlToModuleId.get(url);
        if (!module) return null;
        return dart.getSourceMap(module);
      });
  }
  if (typeof document != 'undefined') {
    window.postMessage({ type: "DDC_STATE_CHANGE", state: "start" }, "*");
  }

  /* MAIN_EXTENSION_MARKER */
  (app.test__disable_sound_null_safety_test$46dart$46browser_test || app.disable_sound_null_safety_test$46dart$46browser_test).main();
  var bootstrap = {
      hot$onChildUpdate: function(childName, child) {
        // Special handling for the multi-root scheme uris. We need to strip
        // out the scheme and the top level directory, to match the source path
        // that chrome sees.
        if (childName.startsWith('org-dartlang-app:///')) {
          childName = childName.substring('org-dartlang-app:///'.length);
          var firstSlash = childName.indexOf('/');
          if (firstSlash == -1) return false;
          childName = childName.substring(firstSlash + 1);
        }
        if (childName === "disable_sound_null_safety_test.dart.browser_test.dart") {
          // Clear static caches.
          dart_sdk.dart.hotRestart();
          child.main();
          return true;
        }
      }
    }
  dart_sdk.dart.trackLibraries("disable_sound_null_safety_test.dart.browser_test.dart.bootstrap", {
    "disable_sound_null_safety_test.dart.browser_test.dart.bootstrap": bootstrap
  }, '');
  return {
    bootstrap: bootstrap
  };
});
})();
