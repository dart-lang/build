# NOTICE: THESE HOOKS WILL SOON BE DEPRECATED/DELETED

If this breaks your use case please comment on this issue
https://github.com/dart-lang/webdev/issues/434

## What is Hot Module Reloading?

This is a feature that allows you to speed up development process by reducing time between writing
code and seeing the result. It detects changes in your code and automatically reloads the minimum
amount of js modules on the page for changes to take effect.

If something depends on changed module A, it may have some instances of A's types, functions and
objects closured, so reloading A itself doesnt invalidate closure. In a basic configuration,
hot-reloading reloads all the modules from a changed module up to the root module of the application
and reruns `main()` function for changes to take effect. This means that without special measures
the state of your application won't be preserved, nevertheless hot-reloading is much faster than
full page reloading.

## Turning hot-reloading on

`build_runner` server has built-in support of hot reloading. To activate it just run the `serve`
command with the `--hot-reload` option.

## Using hooks to handle module reloading

Each module where changes are detected is marked as invalidated. For each invalidated module three
hooks will be called to determine if it is possible to handle the reload, or if all parents (other
modules that depends on this one) should be marked as invalidated too. To implement the hook all you
need to do is to define a top-level publicly exported function with the name and signature of a hook.
The hooks are:

### `Object hot$onDestroy();`

This function will be called on old version of module before unloading.

Implement this function with any code to release resources before destroy.

Any object returned from this function will be passed to update hooks. Use
it to save any state you need to be preserved between hot reloadings.
Try not to use any custom types here, as it might prevent their code from
reloading. Better serialise to JSON or plain types.

### `bool hot$onSelfUpdate([Object data])`

This function will be called on new version of module after reloading.

If any state was saved from previous version, it will be passed to `data`.

Implement this function to handle update of the module itself.

May return nullable bool. To indicate that reload completes successfully
return `true`. To indicate that hot-reload is undoable return `false` - this
will lead to full page reload. If `null` returned, reloading will be
propagated to the parent.

### `bool hot$onChildUpdate(String childPath, Object child, [Object data]);`

This function will be called on current version of module parent after child
reloading.

The name of the child library will be provided in `childPath`. New version of child
module object will be provided in `child`.
If any state was saved from previous version, it will be passed to `data`.

Implement this function to handle update of child modules.

Accessing properties of provided `child` object is tricky thing. As dart libraries have no type
themselves, the provided object is an arbitrary JavaScript object with properties matched with
exported symbols in the child library. To access them you need to use either
[`package:js`](https://pub.dev/packages/js) or 
[`dart:js_util`](https://api.dart.dev/stable/2.4.0/dart-js_util/dart-js_util-library.html).
See example below for details how to use it.

May return nullable bool. To indicate that reload of child completes
successfully return `true`. To indicate that hot-reload is undoable for this
child return `false` - this will lead to full page reload. If `null` returned,
reloading will be propagated to current module itself.

## Examples

### Implement `hot$onDestroy` for root module

Lets's assume you do some DOM modifications in your `main()` function. DOM is preserved between
module reloadings, but state of your code is not. This may end in a situation where after reloading
DOM is not in the same state you application will assume it is. 

To resolve this situation you need to implement `hot$onDestroy` hook, to restore the state of DOM
to what your application expects. You may also change your initial code to handle all possible
states of the DOM, but it may have an impact on production performance or behavior, while HMR hooks
will be just optimized out by dart2js as unused.

```dart
import 'dart:html';

var _id = 'hello';

void main() {
  var helloDiv = Element.div()
    ..id = _id
    ..text = 'Hello Dart';
  document.body.append(helloDiv);
}

Object hot$onDestroy() {
  document.body.querySelectorAll('#$_id').forEach((e) => e.remove());
}
```

### Handling reloading of child modules

Lets assume you have a builder that transforms your css files into dart code exporting the string.
As this string doesn't have any impact on your logic, you want to handle reloading of these modules,
to prevent parent from reloading

To simplify the example, lets assume we have `addCss` and `removeCss` methods that do real DOM
modifications. In this example we will just add and remove the styles from a `Set`.

```dart
// your_package/lib/styles.dart

var _styles = new Set<String>();

void addCss(String css) {
  _styles.add(css);
}

void removeCss(String css) {
  _styles.remove(css);
}
```

```dart
// your_package/web/main.dart

import 'package:js/js.dart';
import 'package:your_package/src/css_file.css.shim.dart' as css_file;
import 'package:your_package/styles.dart';

// You should encapsulate usages of your library to one place you are able to substitute 
// (non-final variable in this case)
var _css_style = css_file.styles;

void main() {
  addCss(_css_style);
  
  // Some stateful code you don't want to reinitialise
  // ...
}

// We need to describe library structure as js object to be able to use it
@JS()
abstract class StylesLib {
  @JS()
  external String get styles;
}

bool hot$onChildUpdate(String id, Object child) {
  if (id == 'package:your_package/src/css_file.css.shim.dart') {
    removeCss(_css_style);
    _css_style = (child as StylesLib).styles;
    addCss(_css_style);
    return true;
  }
}
```

Another implementation of `hot$onChildUpdate` using `dart:js_util` may be the following:
```dart
import 'dart:js_util';

bool hot$onChildUpdate(String id, Object child) {
  if (id == 'package:your_package/src/css_file.css.shim.dart') {
    removeCss(_css_style);
    _css_style = getProperty(child, 'styles');
    addCss(_css_style);
    return true;
  }
}
```

## Known issues

- Creating new modules, removing them or otherwise changing dependency grapth results in full page
  reload. [#1761](https://github.com/dart-lang/build/issues/1761)
- Libraries are often bundled together in one module. In most cases `hot$onChildUpdate` hook for
  such bundled modules won't work - code will be executed, but parent module will still be reloaded.
  That happens because current requirement is for all libraries in module to know how to handle
  child updates. If you actively use this hook, you may consider turning on `fine` build strategy in
  your `build.yaml` either globally or only for your root package, to work around this issue. But
  this will also slow down your builds. [#1767](https://github.com/dart-lang/build/issues/1767)
  
  - Globally
    ```yaml
    global_options:
      build_modules|modules:
        options:
          strategy: fine
    ```
  
  - For root package
    ```yaml
    targets:
      $default:
        builders:
          build_modules|modules:
            options:
              strategy: fine
    ```
