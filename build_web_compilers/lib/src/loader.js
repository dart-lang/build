// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// For apps compiled both with dart2js and dart2wasm, this entrypoint script
// is responsible for detecting browser features and then loading either the
// wasm or the JS bundle depending on which features are supported.
//
// Note: build_web_compiler loads a minified version of this file. To re-generate
// it, run:
//
// esbuild lib/src/loader.js --bundle "--external:*.mjs" --format=esm --minify > lib/src/loader.min.js

function supportsWasmGC() {
  // This attempts to instantiate a wasm module that only will validate if the
  // final WasmGC spec is implemented in the browser.
  //
  // Copied from https://github.com/GoogleChromeLabs/wasm-feature-detect/blob/main/src/detectors/gc/index.js
  const bytes = [0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 95, 1, 120, 0];
  return WebAssembly && WebAssembly.validate(new Uint8Array(bytes));
}

function resolveUrlWithSegments(...segments) {
  return new URL(joinPathSegments(...segments), document.baseURI).toString()
}

(async () => {
  if (supportsWasmGC()) {
    let { instantiate, invoke } = await import("./{{basename}}.mjs");

    let modulePromise = WebAssembly.compileStreaming(fetch("{{basename}}.wasm"));
    let instantiated = await instantiate(modulePromise, {});
    invoke(instantiated, []);
  } else {
    const scriptTag = document.createElement("script");
    scriptTag.type = "application/javascript";
    scriptTag.src = resolveUrlWithSegments("./{{basename}}.bootstrap.js");
    document.head.append(scriptTag);
  }
})();
