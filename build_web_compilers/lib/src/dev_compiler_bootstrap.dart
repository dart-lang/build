// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
// ignore: no_leading_underscores_for_library_prefixes
import 'package:path/path.dart' as _p;
import 'package:pool/pool.dart';

import 'common.dart';
import 'platforms.dart';
import 'web_entrypoint_builder.dart';

/// Alias `_p.url` to `p`.
_p.Context get _context => _p.url;

final _modulePartialExtension = _context.withoutExtension(jsModuleExtension);

final stackTraceMapperPath =
    'packages/build_web_compilers/src/'
    'dev_compiler_stack_trace/stack_trace_mapper.dart.js';

/// Bootstraps a ddc application, creating the main entrypoint as well as the
/// bootstrap and digest entrypoints.
///
/// If [requiredAssets] is provided then this will ensure those assets are
/// available to the app by making them inputs of this build action.
Future<void> bootstrapDdc(
  BuildStep buildStep, {
  Iterable<AssetId> requiredAssets = const [],
  String entrypointExtension = jsEntrypointExtension,
  required bool? nativeNullAssertions,
  bool usesWebHotReload = false,
  bool ddcLibraryBundle = false,
  bool unsafeAllowUnsupportedModules = false,
}) async {
  // Ensures that the sdk resources are built and available.
  await _ensureResources(buildStep, requiredAssets);

  final dartEntrypointId = buildStep.inputId;
  final moduleId = buildStep.inputId.changeExtension(
    moduleExtension(ddcPlatform),
  );
  final module = Module.fromJson(
    json.decode(await buildStep.readAsString(moduleId)) as Map<String, dynamic>,
  );

  // First, ensure all transitive modules are built.
  List<AssetId> transitiveJsModules;
  try {
    transitiveJsModules = await _ensureTransitiveJsModules(
      module,
      buildStep,
      computeStronglyConnectedComponents: !usesWebHotReload,
      throwIfUnsupported: !unsafeAllowUnsupportedModules,
    );
  } on UnsupportedModules catch (e) {
    final librariesString = (await e.exactLibraries(buildStep).toList())
        .map(
          (lib) => AssetId(
            lib.id.package,
            lib.id.path.replaceFirst(moduleLibraryExtension, '.dart'),
          ),
        )
        .join('\n');
    log.warning('''
Skipping compiling ${buildStep.inputId} with ddc because some of its
transitive libraries have sdk dependencies that not supported on this platform:

$librariesString
''');
    return;
  }
  final jsId = module.primarySource.changeExtension(jsModuleExtension);
  final appModuleName = ddcModuleName(jsId);
  final appDigestsOutput = dartEntrypointId.changeExtension(
    digestsEntrypointExtension,
  );
  final mergedMetadataOutput = dartEntrypointId.changeExtension(
    mergedMetadataExtension,
  );

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
  final oldAppModuleScope = toJSIdentifier(
    _context.withoutExtension(_context.basename(buildStep.inputId.path)),
  );

  // Like above but with a package-relative entrypoint.
  final appModuleScope = pathToJSIdentifier(
    _context.withoutExtension(buildStep.inputId.path),
  );

  final bootstrapId = dartEntrypointId.changeExtension(ddcBootstrapExtension);
  final bootstrapEndId = dartEntrypointId.changeExtension(
    ddcBootstrapEndExtension,
  );

  final dartEntrypointParts = _context.split(dartEntrypointId.path);
  final packageName = module.primarySource.package;
  final entrypointLibraryName =
      ddcLibraryBundle
          ? _context.joinAll([
            // Convert to a package: uri for files under lib.
            if (dartEntrypointParts.first == 'lib') 'package:$packageName',
            ...dartEntrypointParts,
          ])
          : _context.joinAll([
            // Convert to a package: uri for files under lib.
            if (dartEntrypointParts.first == 'lib') 'package:$packageName',
            // Strip top-level directory from the path.
            ...dartEntrypointParts.skip(1),
          ]);

  final entrypointJsId = dartEntrypointId.changeExtension(entrypointExtension);

  // Map from module name to module path for custom modules.
  final modulePaths = SplayTreeMap<String, String>();
  String entrypointJsContent;
  String bootstrapContent;
  String bootstrapEndContent;
  if (ddcLibraryBundle) {
    final ddcSdkUrl =
        r'packages/build_web_compilers/src/dev_compiler/dart_sdk.js';
    modulePaths['dart_sdk'] = ddcSdkUrl;
    for (final jsId in transitiveJsModules) {
      // Strip out the top level dir from the path for any module, and set it to
      // `packages/` for lib modules. We set baseUrl to `/` to simplify things,
      // and we only allow you to serve top level directories.
      final moduleName = ddcModuleName(jsId);
      final libraryId = ddcLibraryId(jsId);
      modulePaths[libraryId] =
          jsId.path.startsWith('lib')
              ? '$moduleName$jsModuleExtension'
              : _context.joinAll(_context.split(jsId.path).skip(1));
    }
    final bootstrapEndModuleName = _context.relative(
      bootstrapEndId.path,
      from: _context.dirname(bootstrapId.path),
    );
    bootstrapContent = generateDDCLibraryBundleMainModule(
      entrypoint: entrypointLibraryName,
      nativeNullAssertions: nativeNullAssertions ?? false,
      onLoadEndBootstrap: bootstrapEndModuleName,
    );
    final bootstrapModuleName = _context.relative(
      bootstrapId.path,
      from: _context.dirname(dartEntrypointId.path),
    );
    entrypointJsContent = generateDDCLibraryBundleBootstrapScript(
      entrypoint: entrypointLibraryName,
      ddcSdkUrl: ddcSdkUrl,
      ddcModuleLoaderUrl:
          'packages/build_web_compilers/src/dev_compiler/ddc_module_loader.js',
      mainBoostrapperUrl: bootstrapModuleName,
      mapperUrl: stackTraceMapperPath,
      isWindows: Platform.isWindows,
      scriptIdsToPath: modulePaths,
    );
    bootstrapEndContent = generateDDCLibraryBundleOnLoadEndBootstrap();
  } else {
    modulePaths['dart_sdk'] =
        r'packages/build_web_compilers/src/dev_compiler/dart_sdk';
    for (final jsId in transitiveJsModules) {
      // Strip out the top level dir from the path for any module, and set it to
      // `packages/` for lib modules. We set baseUrl to `/` to simplify things,
      // and we only allow you to serve top level directories.
      final moduleName = ddcModuleName(jsId);
      modulePaths[moduleName] = _context.withoutExtension(
        jsId.path.startsWith('lib')
            ? '$moduleName$jsModuleExtension'
            : _context.joinAll(_context.split(jsId.path).skip(1)),
      );
    }
    final bootstrapModuleName = _context.withoutExtension(
      _context.relative(
        bootstrapId.path,
        from: _context.dirname(dartEntrypointId.path),
      ),
    );
    entrypointJsContent = _entryPointJs(bootstrapModuleName);
    bootstrapContent =
        (StringBuffer('$_entrypointExtensionMarker\n(function() {\n')
              ..write(
                _dartLoaderSetup(
                  modulePaths,
                  _p.url.relative(
                    appDigestsOutput.path,
                    from: _p.url.dirname(bootstrapId.path),
                  ),
                ),
              )
              ..write(_requireJsConfig)
              ..write(
                _appBootstrap(
                  bootstrapModuleName: bootstrapModuleName,
                  entrypointLibraryName: entrypointLibraryName,
                  moduleName: appModuleName,
                  moduleScope: appModuleScope,
                  nativeNullAssertions: nativeNullAssertions,
                  oldModuleScope: oldAppModuleScope,
                ),
              ))
            .toString();
    // Unused for the AMD module system.
    bootstrapEndContent = '';
  }

  await buildStep.writeAsString(entrypointJsId, entrypointJsContent);
  await buildStep.writeAsString(bootstrapId, bootstrapContent);
  await buildStep.writeAsString(bootstrapEndId, bootstrapEndContent);

  // Output the digests and merged_metadata for transitive modules.
  // These can be consumed for hot reloads and debugging.
  final mergedMetadataContent = StringBuffer();
  final moduleDigests = <String, String>{};
  for (final jsId in transitiveJsModules) {
    mergedMetadataContent.writeln(
      await buildStep.readAsString(jsId.changeExtension('.js.metadata')),
    );
    moduleDigests[_moduleDigestKey(jsId)] = '${await buildStep.digest(jsId)}';
  }
  await buildStep.writeAsString(appDigestsOutput, jsonEncode(moduleDigests));
  await buildStep.writeAsString(
    mergedMetadataOutput,
    mergedMetadataContent.toString(),
  );
}

String _moduleDigestKey(AssetId jsId) =>
    '${ddcModuleName(jsId)}$jsModuleExtension';

final _lazyBuildPool = Pool(16);

/// Ensures that all transitive js modules for [module] are available and built.
///
/// Throws an [UnsupportedModules] exception if there are any
/// unsupported modules.
Future<List<AssetId>> _ensureTransitiveJsModules(
  Module module,
  BuildStep buildStep, {
  bool computeStronglyConnectedComponents = true,
  bool throwIfUnsupported = true,
}) async {
  // Collect all the modules this module depends on, plus this module.
  final transitiveDeps = await module.computeTransitiveDependencies(
    buildStep,
    throwIfUnsupported: throwIfUnsupported,
    computeStronglyConnectedComponents: computeStronglyConnectedComponents,
  );

  final jsModules = [
    module.primarySource.changeExtension(jsModuleExtension),
    for (final dep in transitiveDeps)
      dep.primarySource.changeExtension(jsModuleExtension),
  ];
  // Check that each module is readable, and warn otherwise.
  await Future.wait(
    jsModules.map((jsId) async {
      if (await _lazyBuildPool.withResource(() => buildStep.canRead(jsId))) {
        return;
      }
      final errorsId = jsId.addExtension('.errors');
      await buildStep.canRead(errorsId);
      log.warning(
        'Unable to read $jsId, check your console or the '
        '`.dart_tool/build/generated/${errorsId.package}/${errorsId.path}` '
        'log file.',
      );
    }),
  );
  return jsModules;
}

/// Code that actually imports the [moduleName] module, and calls the
/// `[moduleScope].main()` function on it.
///
/// Also performs other necessary initialization.
String _appBootstrap({
  required String bootstrapModuleName,
  required String moduleName,
  required String moduleScope,
  required String entrypointLibraryName,
  required String oldModuleScope,
  required bool? nativeNullAssertions,
}) {
  final nativeAssertsCode =
      nativeNullAssertions == null
          ? ''
          : 'dart_sdk.dart.nativeNonNullAsserts($nativeNullAssertions);';
  return '''
define("$bootstrapModuleName", ["$moduleName", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk.dart.setStartAsyncSynchronously(true);
  $nativeAssertsCode
  dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
  $_initializeTools
  $_mainExtensionMarker
  (app.$moduleScope || app.$oldModuleScope).main();
  var bootstrap = {
      hot\$onChildUpdate: function(childName, child) {
        // Special handling for the multi-root scheme uris. We need to strip
        // out the scheme and the top level directory, to match the source path
        // that chrome sees.
        if (childName.startsWith('$multiRootScheme:///')) {
          childName = childName.substring('$multiRootScheme:///'.length);
          var firstSlash = childName.indexOf('/');
          if (firstSlash == -1) return false;
          childName = childName.substring(firstSlash + 1);
        }
        if (childName === "$entrypointLibraryName") {
          // Clear static caches.
          dart_sdk.dart.hotRestart();
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
}

/// The actual entrypoint JS file which injects all the necessary scripts to
/// run the app.
String _entryPointJs(String bootstrapModuleName) => '''
(function() {
  $_currentDirectoryScript
  $_baseUrlScript

  var mapperUri = baseUrl + "$stackTraceMapperPath";
  var requireUri = baseUrl +
      "packages/build_web_compilers/src/dev_compiler/require.js";
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
String _dartLoaderSetup(Map<String, String> modulePaths, String appDigests) =>
    '''
$_currentDirectoryScript
$_baseUrlScript
let modulePaths = ${const JsonEncoder.withIndent(" ").convert(modulePaths)};
if(!window.\$dartLoader) {
   window.\$dartLoader = {
     appDigests: _currentDirectory + '$appDigests',
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

/// Marker comment used by tools to identify the entrypoint file,
/// to inject custom code.
final _entrypointExtensionMarker = '/* ENTRYPOINT_EXTENTION_MARKER */';

/// Marker comment used by tools to identify the main function
/// to inject custom code.
final _mainExtensionMarker = '/* MAIN_EXTENSION_MARKER */';

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

/// Ensures that all of [resources] are built successfully, and adds them as
/// an input dependency to this action.
///
/// This also has the effect of ensuring these resources are present whenever
/// a DDC app is built - reducing the need to explicitly list these files as
/// build filters.
Future<void> _ensureResources(
  BuildStep buildStep,
  Iterable<AssetId> resources,
) async {
  for (final resource in resources) {
    if (!await buildStep.canRead(resource)) {
      throw StateError('Unable to locate required sdk resource $resource');
    }
  }
}

const _simpleLoaderScript = r'''
window.$dartCreateScript = (function() {
  // Find the nonce value. (Note, this is only computed once.)
  var scripts = Array.from(document.getElementsByTagName("script"));
  var nonce;
  scripts.some(
      script => (nonce = script.nonce || script.getAttribute("nonce")));
  // If present, return a closure that automatically appends the nonce.
  if (nonce) {
    return function() {
      var script = document.createElement("script");
      script.nonce = nonce;
      return script;
    };
  } else {
    return function() {
      return document.createElement("script");
    };
  }
})();

// Loads a module [relativeUrl] relative to [root].
//
// If not specified, [root] defaults to the directory serving the main app.
var forceLoadModule = function (relativeUrl, root) {
  var actualRoot = root ?? _currentDirectory;
  return new Promise(function(resolve, reject) {
    var script = self.$dartCreateScript();
    let policy = {
      createScriptURL: function(src) {return src;}
    };
    if (self.trustedTypes && self.trustedTypes.createPolicy) {
      policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
    }
    script.onload = resolve;
    script.onerror = reject;
    script.src = policy.createScriptURL(actualRoot + relativeUrl);
    document.head.appendChild(script);
  });
};
''';

String generateDDCLibraryBundleBootstrapScript({
  required String entrypoint,
  required String ddcSdkUrl,
  required String ddcModuleLoaderUrl,
  required String mainBoostrapperUrl,
  required String mapperUrl,
  required bool isWindows,
  required Map<String, String> scriptIdsToPath,
}) {
  final scriptsJs = StringBuffer();
  scriptIdsToPath.forEach((id, path) {
    scriptsJs.write('{"src": "$path", "id": "$id"},\n');
  });
  // Write the "true" main boostrapper last as part of the loader's convention.
  scriptsJs.write('{"src": "$mainBoostrapperUrl", "id": "data-main"}\n');
  final boostrapScript = '''
// Save the current directory so we can access it in a closure.
  let _currentDirectory = (function () {
    let _url = document.currentScript.src;
    let lastSlash = _url.lastIndexOf('/');
    if (lastSlash == -1) return _url;
    let currentDirectory = _url.substring(0, lastSlash + 1);
    return currentDirectory;
  })();

  let trimmedDirectory = _currentDirectory.endsWith("/") ?
    _currentDirectory.substring(0, _currentDirectory.length - 1)
    : _currentDirectory;

$_simpleLoaderScript

(function() {
  let appName = "$multiRootScheme:///$entrypoint";

  // Load pre-requisite DDC scripts. We intentionally use invalid names to avoid
  // namespace clashes.
  let prerequisiteScripts = [
    {
      "src": "$ddcModuleLoaderUrl",
      "id": "ddc_module_loader \x00"
    },
    {
      "src": "$mapperUrl",
      "id": "dart_stack_trace_mapper \x00"
    }
  ];

  // Load ddc_module_loader.js to access DDC's module loader API.
  let prerequisiteLoads = [];
  for (let i = 0; i < prerequisiteScripts.length; i++) {
    prerequisiteLoads.push(forceLoadModule(prerequisiteScripts[i].src));
  }
  Promise.all(prerequisiteLoads).then((_) => afterPrerequisiteLogic());

  // Save the current script so we can access it in a closure.
  var _currentScript = document.currentScript;

  // Create a policy if needed to load the files during a hot restart.
  let policy = {
    createScriptURL: function(src) {return src;}
  };
  if (self.trustedTypes && self.trustedTypes.createPolicy) {
    policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
  }

  var afterPrerequisiteLogic = function() {
    window.\$dartLoader.rootDirectories.push(_currentDirectory);
    let scripts = [${scriptsJs.toString()}];

    let loadConfig = new window.\$dartLoader.LoadConfiguration();
    // TODO(srujzs): Verify this is sufficient for Windows.
    loadConfig.isWindows = $isWindows;
    loadConfig.root = trimmedDirectory;
    loadConfig.bootstrapScript = scripts[scripts.length - 1];

    loadConfig.loadScriptFn = function(loader) {
      loader.addScriptsToQueue(scripts, null);
      loader.loadEnqueuedModules();
    }
    loadConfig.ddcEventForLoadStart = /* LOAD_ALL_MODULES_START */ 1;
    loadConfig.ddcEventForLoadedOk = /* LOAD_ALL_MODULES_END_OK */ 2;
    loadConfig.ddcEventForLoadedError = /* LOAD_ALL_MODULES_END_ERROR */ 3;

    let loader = new window.\$dartLoader.DDCLoader(loadConfig);

    // Record prerequisite scripts' fully resolved URLs.
    prerequisiteScripts.forEach(script => loader.registerScript(script));

    // Note: these variables should only be used in non-multi-app scenarios
    // since they can be arbitrarily overridden based on multi-app load order.
    window.\$dartLoader.loadConfig = loadConfig;
    window.\$dartLoader.loader = loader;

    // Begin loading libraries
    loader.nextAttempt();

    // Set up stack trace mapper.
    if (window.\$dartStackTraceUtility &&
        !window.\$dartStackTraceUtility.ready) {
      window.\$dartStackTraceUtility.ready = true;
      window.\$dartStackTraceUtility.setSourceMapProvider(function(url) {
        var baseUrl = window.location.protocol + '//' + window.location.host;
        url = url.replace(baseUrl + '/', '');
        if (url == 'dart_sdk.js') {
          return dartDevEmbedder.debugger.getSourceMap('dart_sdk');
        }
        url = url.replace(".lib.js", "");
        return dartDevEmbedder.debugger.getSourceMap(url);
      });
    }

    let currentUri = _currentScript.src;
    // We should have written a file containing all the scripts that need to be
    // reloaded into the page. This is then read when a hot restart is triggered
    // in DDC via the `\$dartReloadModifiedModules` callback.
    let reloadedSources = _currentDirectory + 'reloaded_sources.json';

    if (!window.\$dartReloadModifiedModules) {
      window.\$dartReloadModifiedModules = (function(appName, callback) {
        const xhttp = new XMLHttpRequest();
        xhttp.withCredentials = true;
        xhttp.onreadystatechange = function() {
          // https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/readyState
          if (this.readyState == 4 && this.status == 200 || this.status == 304) {
            const scripts = JSON.parse(this.responseText);
            let numToLoad = 0;
            let numLoaded = 0;
            for (let i = 0; i < scripts.length; i++) {
              const script = scripts[i];
              const module = script.module;
              if (module == null) continue;
              const src = script.src;
              const oldSrc = window.\$dartLoader.moduleIdToUrl.get(module);

              // We might actually load from a different uri, delete the old one
              // just to be sure.
              window.\$dartLoader.urlToModuleId.delete(oldSrc);

              window.\$dartLoader.moduleIdToUrl.set(module, src);
              window.\$dartLoader.urlToModuleId.set(src, module);

              numToLoad++;

              let el = document.getElementById(module);
              if (el) el.remove();
              el = window.\$dartCreateScript();
              el.src = policy.createScriptURL(src);
              el.async = false;
              el.defer = true;
              el.id = module;
              el.onload = function() {
                numLoaded++;
                if (numToLoad == numLoaded) callback();
              };
              document.head.appendChild(el);
            }
            // Call `callback` right away if we found no updated scripts.
            if (numToLoad == 0) callback();
          }
        };
        xhttp.open("GET", reloadedSources, true);
        xhttp.send();
      });
    }
  };
})();
''';
  return boostrapScript;
}

String generateDDCLibraryBundleMainModule({
  required String entrypoint,
  required bool nativeNullAssertions,
  required String onLoadEndBootstrap,
}) {
  // The typo below in "EXTENTION" is load-bearing, package:build depends on it.
  return '''
/* ENTRYPOINT_EXTENTION_MARKER */

(function() {
  let appName = "$multiRootScheme:///$entrypoint";
  dartDevEmbedder.debugger.registerDevtoolsFormatter();

  // Set up a final script that lets us know when all scripts have been loaded.
  // Only then can we call the main method.
  let onLoadEndSrc = '$onLoadEndBootstrap';
  window.\$dartLoader.loadConfig.bootstrapScript = {
    src: onLoadEndSrc,
    id: onLoadEndSrc,
  };
  window.\$dartLoader.loadConfig.tryLoadBootstrapScript = true;
  // Should be called by $onLoadEndBootstrap once all the scripts have been
  // loaded.
  window.$_onLoadEndCallback = function() {
    let child = {};
    child.main = function() {
      let sdkOptions = {
        nativeNonNullAsserts: $nativeNullAssertions,
      };
      dartDevEmbedder.runMain(appName, sdkOptions);
    }
    /* MAIN_EXTENSION_MARKER */
    child.main();
  }
  // Call this immediately in build_web_compilers.
  window.$_onLoadEndCallback();
})();
''';
}

String generateDDCLibraryBundleOnLoadEndBootstrap() {
  return '''window.$_onLoadEndCallback();''';
}

const _onLoadEndCallback = r'$onLoadEndCallback';
