// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as _p; // ignore: library_prefixes
import 'package:pool/pool.dart';

import 'common.dart';
import 'ddc_names.dart';
import 'dev_compiler_builder.dart';
import 'web_entrypoint_builder.dart';

/// Alias `_p.url` to `p`.
_p.Context get _context => _p.url;

var _modulePartialExtension = _context.withoutExtension(jsModuleExtension);

Future<Null> bootstrapDdc(BuildStep buildStep,
    {bool useKernel,
    bool buildRootAppSummary,
    bool enableSyncAsync,
    bool ignoreCastFailures}) async {
  buildRootAppSummary ??= false;
  enableSyncAsync ??= enableSyncAsyncDefault;
  ignoreCastFailures ??= false;
  useKernel ??= false;
  var dartEntrypointId = buildStep.inputId;
  var moduleId =
      buildStep.inputId.changeExtension(moduleExtension(DartPlatform.dartdevc));
  var module = Module.fromJson(json
      .decode(await buildStep.readAsString(moduleId)) as Map<String, dynamic>);

  if (buildRootAppSummary) await buildStep.canRead(module.linkedSummaryId);

  // First, ensure all transitive modules are built.
  var transitiveDeps = await _ensureTransitiveModules(module, buildStep);
  var jsId = module.jsId(jsModuleExtension);
  var appModuleName = _ddcModuleName(jsId);

  // The name of the entrypoint dart library within the entrypoint JS module.
  //
  // This is used to invoke `main()` from within the bootstrap script.
  //
  // TODO(jakemac53): Sane module name creation, this only works in the most
  // basic of cases.
  //
  // See https://github.com/dart-lang/sdk/issues/27262 for the root issue
  // which will allow us to not rely on the naming schemes that dartdevc uses
  // internally, but instead specify our own.
  var appModuleScope = toJSIdentifier(() {
    if (useKernel) {
      var basename = _context.basename(jsId.path);
      return basename.substring(0, basename.length - jsModuleExtension.length);
    } else {
      Iterable<String> scope = _context.split(_ddcModuleName(jsId));
      if (scope.first == 'packages') {
        scope = scope.skip(1);
      }
      return scope.skip(1).join('__');
    }
  }());

  // Map from module name to module path for custom modules.
  var modulePaths =
      SplayTreeMap.of({'dart_sdk': r'packages/$sdk/dev_compiler/amd/dart_sdk'});
  var transitiveJsModules = [jsId]
    ..addAll(transitiveDeps.map((dep) => dep.jsId(jsModuleExtension)));
  for (var jsId in transitiveJsModules) {
    // Strip out the top level dir from the path for any module, and set it to
    // `packages/` for lib modules. We set baseUrl to `/` to simplify things,
    // and we only allow you to serve top level directories.
    var moduleName = _ddcModuleName(jsId);
    modulePaths[moduleName] = _context.withoutExtension(
        jsId.path.startsWith('lib')
            ? '$moduleName$jsModuleExtension'
            : _context.joinAll(_context.split(jsId.path).skip(1)));
  }

  var bootstrapId = dartEntrypointId.changeExtension(ddcBootstrapExtension);
  var bootstrapModuleName = _context.withoutExtension(_context.relative(
      bootstrapId.path,
      from: _context.dirname(dartEntrypointId.path)));

  var bootstrapContent =
      StringBuffer('$_entrypointExtensionMarker\n(function() {\n');
  bootstrapContent.write(_dartLoaderSetup(modulePaths));
  bootstrapContent.write(_requireJsConfig);

  // Strip top-level directory
  var appModuleSource =
      _context.joinAll(_context.split(module.primarySource.path).sublist(1));

  bootstrapContent.write(_appBootstrap(bootstrapModuleName, appModuleName,
      appModuleScope, appModuleSource, ignoreCastFailures, enableSyncAsync));

  await buildStep.writeAsString(bootstrapId, bootstrapContent.toString());

  var entrypointJsContent = _entryPointJs(bootstrapModuleName);
  await buildStep.writeAsString(
      dartEntrypointId.changeExtension(jsEntrypointExtension),
      entrypointJsContent);
}

final _lazyBuildPool = Pool(16);

/// Ensures that all transitive js modules for [module] are available and built.
Future<List<Module>> _ensureTransitiveModules(
    Module module, AssetReader reader) async {
  // Collect all the modules this module depends on, plus this module.
  var transitiveDeps = await module.computeTransitiveDependencies(reader);
  var jsModules = transitiveDeps
      .map((module) => module.jsId(jsModuleExtension))
      .toList()
        ..add(module.jsId(jsModuleExtension));
  // Check that each module is readable, and warn otherwise.
  await Future.wait(jsModules.map((jsId) async {
    if (await _lazyBuildPool.withResource(() => reader.canRead(jsId))) return;
    var errorsId = jsId.addExtension('.errors');
    await reader.canRead(errorsId);
    log.warning('Unable to read $jsId, check your console or the '
        '`.dart_tool/build/generated/${errorsId.package}/${errorsId.path}` '
        'log file.');
  }));
  return transitiveDeps;
}

/// The module name according to ddc for [jsId] which represents the real js
/// module file.
String _ddcModuleName(AssetId jsId) {
  var jsPath = jsId.path.startsWith('lib/')
      ? jsId.path.replaceFirst('lib/', 'packages/${jsId.package}/')
      : jsId.path;
  return jsPath.substring(0, jsPath.length - jsModuleExtension.length);
}

/// Code that actually imports the [moduleName] module, and calls the
/// `[moduleScope].main()` function on it.
///
/// Also performs other necessary initialization.
String _appBootstrap(
        String bootstrapModuleName,
        String moduleName,
        String moduleScope,
        String appModuleSource,
        bool ignoreCastFailures,
        bool enableSyncAsync) =>
    '''
define("$bootstrapModuleName", ["$moduleName", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk.dart.ignoreWhitelistedErrors($ignoreCastFailures);
  dart_sdk.dart.setStartAsyncSynchronously($enableSyncAsync);
  dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
$_initializeTools
  app.$moduleScope.main();
  var bootstrap = {
      hot\$onChildUpdate: function(childName, child) {
        if (childName === "$appModuleSource") {
          child.main();
          return true;
        }
      }
    }
  dart_sdk.dart.trackLibraries("$bootstrapModuleName", {
    "$bootstrapModuleName": bootstrap
  }, '');
  return {
    bootstrap: bootstrap
  };
});
})();
''';

/// The actual entrypoint JS file which injects all the necessary scripts to
/// run the app.
String _entryPointJs(String bootstrapModuleName) => '''
(function() {
  $_currentDirectoryScript
  $_baseUrlScript

  var mapperUri = baseUrl + "packages/build_web_compilers/src/" +
      "dev_compiler_stack_trace/stack_trace_mapper.dart.js";
  var requireUri = baseUrl + "packages/\$sdk/dev_compiler/amd/require.js";
  var mainUri = _currentDirectory + "$bootstrapModuleName";

  if (typeof document != 'undefined') {
    var el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = mapperUri;
    document.head.appendChild(el);

    el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = requireUri;
    el.setAttribute("data-main", mainUri);
    document.head.appendChild(el);
  } else {
    importScripts(mapperUri, requireUri);
    require.config({
      baseUrl: baseUrl,
    });
    // TODO: update bootstrap code to take argument - dart-lang/build#1115
    window = self;
    require([mainUri + '.js']);
  }
})();
''';

/// JavaScript snippet to determine the directory a script was run from.
final _currentDirectoryScript = r'''
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
''';

/// Sets up `window.$dartLoader` based on [modulePaths].
String _dartLoaderSetup(Map<String, String> modulePaths) => '''
$_baseUrlScript
let modulePaths = ${const JsonEncoder.withIndent(" ").convert(modulePaths)};
if(!window.\$dartLoader) {
   window.\$dartLoader = {
     moduleIdToUrl: new Map(),
     urlToModuleId: new Map(),
     rootDirectories: new Array(),
     // Used in package:build_runner/src/server/build_updates_client/hot_reload_client.dart
     moduleParentsGraph: new Map(),
     moduleLoadingErrorCallbacks: new Map(),
     forceLoadModule: function (moduleName, callback, onError) {
       // dartdevc only strips the final extension when adding modules to source
       // maps, so we need to do the same.
       if (moduleName.endsWith('$_modulePartialExtension')) {
         moduleName = moduleName.substring(0, moduleName.length - ${_modulePartialExtension.length});
       }
       if (typeof onError != 'undefined') {
         var errorCallbacks = \$dartLoader.moduleLoadingErrorCallbacks;
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
window.\$dartLoader.rootDirectories.push(window.location.origin + baseUrl);
for (let moduleName of Object.getOwnPropertyNames(modulePaths)) {
  let modulePath = modulePaths[moduleName];
  if (modulePath != moduleName) {
    customModulePaths[moduleName] = modulePath;
  }
  var src = window.location.origin + '/' + modulePath + '.js';
  // dartdevc only strips the final extension when adding modules to source
  // maps, so we need to do the same.
  if (moduleName != 'dart_sdk') {
    moduleName += '$_modulePartialExtension';
  }
  if (window.\$dartLoader.moduleIdToUrl.has(moduleName)) {
    continue;
  }
  \$dartLoader.moduleIdToUrl.set(moduleName, src);
  \$dartLoader.urlToModuleId.set(src, moduleName);
}
''';

/// Code to initialize the dev tools formatter, stack trace mapper, and any
/// other tools.
///
/// Posts a message to the window when done.
final _initializeTools = '''
$_baseUrlScript
  dart_sdk._debugger.registerDevtoolsFormatter();
  \$dartLoader.getModuleLibraries = dart_sdk.dart.getModuleLibraries;
  if (window.\$dartStackTraceUtility && !window.\$dartStackTraceUtility.ready) {
    window.\$dartStackTraceUtility.ready = true;
    let dart = dart_sdk.dart;
    window.\$dartStackTraceUtility.setSourceMapProvider(
      function(url) {
        url = url.replace(baseUrl, '/');
        var module = window.\$dartLoader.urlToModuleId.get(url);
        if (!module) return null;
        return dart.getSourceMap(module);
      });
  }
  if (typeof document != 'undefined') {
    window.postMessage({ type: "DDC_STATE_CHANGE", state: "start" }, "*");
  }
''';

/// Require JS config for ddc.
///
/// Sets the base url to `/` so that all modules can be loaded using absolute
/// paths which simplifies a lot of scenarios.
///
/// Sets the timeout for loading modules to infinity (0).
///
/// Sets up the custom module paths.
///
/// Adds error handler code for require.js which requests a `.errors` file for
/// any failed module, and logs it to the console.
final _requireJsConfig = '''
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
        var errorCallbacks = \$dartLoader.moduleLoadingErrorCallbacks.get(module);
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

$_baseUrlScript;

require.config({
    baseUrl: baseUrl,
    waitSeconds: 0,
    paths: customModulePaths
});

const modulesGraph = new Map();
function getRegisteredModuleName(moduleMap) {
  if (\$dartLoader.moduleIdToUrl.has(moduleMap.name + '$_modulePartialExtension')) {
    return moduleMap.name + '$_modulePartialExtension';
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
      if (!\$dartLoader.moduleParentsGraph.has(depName)) {
        \$dartLoader.moduleParentsGraph.set(depName, []);
      }
      \$dartLoader.moduleParentsGraph.get(depName).push(name);
      modulesGraph.get(name).push(depName);
    }
  }
};
''';

/// Marker comment used by build_runner (or any other thinks) to identify
/// entrypoint file, to inject custom code there.
///
/// Should be first line in a file, so server don't need to parse whole body
final _entrypointExtensionMarker = '/* ENTRYPOINT_EXTENTION_MARKER */';

final _baseUrlScript = '''
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
''';
