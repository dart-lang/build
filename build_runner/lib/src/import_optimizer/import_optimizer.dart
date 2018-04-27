import 'dart:async';

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset/cache.dart';
import 'package:build_runner/src/environment/io_environment.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart' as log show Logger;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:build_resolvers/src/resolver.dart';
import 'package:build/src/builder/build_step_impl.dart';

class ImportOptimizer{
  static final log.Logger _log = new log.Logger('ImportOptimizer');
  static final _resolvers = new AnalyzerResolvers();
  static final packageGraph = new PackageGraph.forThisPackage();
  final io = new IOEnvironment(packageGraph, true);

   run(List<String> inputs) async {
    var resourceManager = new ResourceManager();

    var _reader = new CachingAssetReader(io.reader);

    for (var input in inputs){
      await _parseInput(input, _reader, resourceManager);
    }
  }

   Future _parseInput(String input, CachingAssetReader _reader, ResourceManager resourceManager) async {
     var inputId = new AssetId.parse(input);
     var buildStep = new BuildStepImpl(
         inputId,
         [],
         _reader,
         null,
         inputId.package,
         _resolvers,
         resourceManager);
     Resolver resolver = await _resolvers.get(buildStep);
     var lib = await buildStep.inputLibrary;
     var vis = new GatherUsedImportedElementsVisitor(lib);
     lib.unit.accept(vis);
     var libraries = _convertElementToLibrary(vis.usedElements);
     var optLibraries = await _optimizationImport(inputId, libraries, resolver);
     var output = _generateImportText(inputId,lib, optLibraries);
     print(output);
   }

   int _getNodeCount(Iterable<LibraryElement> libImports) {
     var imports = new Set<LibraryElement>();
     _parseLib(Iterable<LibraryElement> libImports) {
       for (var item in libImports) {
         if (imports.add(item) && !item.isDartCore && !item.isInSdk) {
           _parseLib(item.importedLibraries);
           _parseLib(item.exportedLibraries);
         }
       }
     }
     _parseLib(libImports);
     return imports.length;
   }

   Future<Iterable<LibraryElement>> _optimizationImport(AssetId inputId, Iterable<LibraryElement> libraries, Resolver resolver) async {
     var outputImports = new Set<LibraryElement>();
     for (var library in libraries ){
       var source = library.source;
       if (source is AssetBasedSource){
         var assetId = source.assetId;
         var optLibrary = library;
         if (assetId.package != inputId.package && source.assetId.path.contains('/src/')){
           optLibrary = await _getOptLibraryImport(library, resolver);
         }
         outputImports.add(optLibrary);
       } else {
         outputImports.add(library);
       }

     }
     return outputImports;
   }

  String _generateImportText(AssetId inputId, LibraryElement sourceLibrary, Iterable<LibraryElement> libraries) {
    var sb = new StringBuffer();
    sb.writeln('//--------------------------');
    sb.writeln('// FileName: "$inputId"');
    var sourceNodeCount = _getNodeCount(sourceLibrary.importedLibraries);
    var optNodeCount = _getNodeCount(libraries);
    if (sourceNodeCount > optNodeCount) {
      for (var library in libraries) {
        var source = library.source;
        if (source is AssetBasedSource) {
          var assetId = source.assetId;
          var postMessage = '';
          if (assetId.package == inputId.package) {
            postMessage = '/* local import */';
          }
          var generateImport = 'package:${assetId.package}${assetId.path.substring(3)}';
          sb.write("import '$generateImport'; $postMessage");
        } else {
          sb.write("import '${source.uri}';");
        }
        sb.writeln();
      }
    } else {
      sb.writeln('// IMPORTS is optimal!');
    }
    sb.writeln('//-------------------------- old: $sourceNodeCount -> new: $optNodeCount');
    return sb.toString();
  }

  Future<LibraryElement> _getOptLibraryImport(LibraryElement library, Resolver resolver) async {
    var source = library.source as AssetBasedSource;
    var result = library;
    var assets = await io.reader.findAssets(new Glob('lib/**.dart'), package: source.assetId.package).toList();
    for (var assetId in assets) {
      if (!assetId.path.contains('/src/')) {
        try {
          var lib = await resolver.libraryFor(assetId);
          var found = lib.exportedLibraries.firstWhere((exportLib) {
            var sourceLib = exportLib.source;
            return (sourceLib is AssetBasedSource && sourceLib.assetId == source.assetId);
          }, orElse: () => null);
          if (found != null) {
            result = lib;
            break;
          }
        }
        catch (e, s) {
          _log.fine('Error asset: "$assetId" for "${source.assetId}"', e, s);
        }
      }
    }
    return result;
  }

  Iterable<LibraryElement> _convertElementToLibrary(UsedImportedElements usedElements) {
     var libs = new Set<LibraryElement>();
     usedElements.elements.forEach((element) {
       var library = element.library;
       if (library != null &&
           library.isPublic &&
           !library.isPrivate &&
           !library.isDartCore &&
           !library.source.uri.toString().contains(':_')
       ) {
         libs.add(library);
       }
     });
     return libs;
  }

}