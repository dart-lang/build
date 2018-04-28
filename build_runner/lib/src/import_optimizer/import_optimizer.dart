import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset/cache.dart';
import 'package:build_runner/src/environment/io_environment.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart' as log show Logger;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:build_resolvers/src/resolver.dart';
import 'package:build/src/builder/build_step_impl.dart';

class ImportOptimizer{
  static final log.Logger _log = new log.Logger('ImportOptimizer');
  static final _resolvers = new AnalyzerResolvers();
  static final packageGraph = new PackageGraph.forThisPackage();
  final io = new IOEnvironment(packageGraph, true);
  final _resourceManager = new ResourceManager();
  final WorkResult _workResult = new WorkResult();
  CachingAssetReader _reader;

  optimizePackage(String package) async {
    _log.info("Optimization package: '$package'");
    var assets = (await io.reader.findAssets(new Glob('lib/**.dart'), package: package).toList()).map((item)=>item.toString()).toList();
    optimizeFiles(assets);
  }

  optimizeFiles(Iterable<String> inputs) async {
    var count = inputs.length;
    _log.info('Optimization files: $count');
     _reader = new CachingAssetReader(io.reader);
     var index = 0;
     for (var input in inputs) {
       index++;
       _log.info('$index/$count $input');
       await _parseInput(input);
     }
    _log.info('Optimization completed');
     _showReport();
   }

   Future _parseInput(String input) async {
     var inputId = new AssetId.parse(input);
     var buildStep = new BuildStepImpl(
         inputId,
         [],
         _reader,
         null,
         inputId.package,
         _resolvers,
         _resourceManager);
     Resolver resolver = await _resolvers.get(buildStep);
     try {
       var lib = await buildStep.inputLibrary;
       var vis = new GatherUsedImportedElementsVisitor(lib);
       lib.unit.accept(vis);
       var libraries = _convertElementToLibrary(vis.usedElements);
       var optLibraries = await _optimizationImport(inputId, libraries, resolver);
       var output = _generateImportText(inputId, lib, optLibraries);
       if (output.isNotEmpty) {
         print(output);
       }
     } catch(e,st){
       _log.fine("Skip '$inputId'", e, st);
     }
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
    var sourceNodeCount = _getNodeCount(sourceLibrary.importedLibraries);
    var optNodeCount = _getNodeCount(libraries);
    _workResult.addStatisticFile(inputId, sourceNodeCount, optNodeCount);
    if (sourceNodeCount > optNodeCount) {
      sb.writeln('// FileName: "$inputId" old: $sourceNodeCount -> new: $optNodeCount');
      for (var library in libraries) {
        var source = library.source;
        if (source is AssetBasedSource) {
          var assetId = source.assetId;
          var postMessage = '';
          if (assetId.package == inputId.package) {
            postMessage = '/* local import */';
          }
          var generateImport = 'package:${assetId.package}${assetId.path.substring(3)}';
          sb.writeln("import '$generateImport'; $postMessage");
        } else {
          sb.writeln("import '${source.uri}';");
        }
      }
    }
//    else {
//      sb.writeln('// FileName: "$inputId" IMPORTS is optimal!');
//    }
    return sb.toString();
  }

  Future<LibraryElement> _getOptLibraryImport(LibraryElement library, Resolver resolverI) async {
    var source = library.source as AssetBasedSource;
    var result = library;
    var resultImportsCount = 99999999;
    var assets = await io.reader.findAssets(new Glob('lib/**.dart'), package: source.assetId.package).toList();
    for (var assetId in assets) {
      if (!assetId.path.contains('/src/')) {
        try {
          var resolver = resolverI;
          if (!await resolver.isLibrary(assetId)){
            resolver = await _resolvers.get(new BuildStepImpl(assetId, [], _reader, null, assetId.package, _resolvers, _resourceManager));
          }
          if (!await resolver.isLibrary(assetId)){
            //skip
            continue;
          }
          var lib = await resolver.libraryFor(assetId);
          var count = _getNodeCount(lib.exportedLibraries);
          if (resultImportsCount > count) {
            if (_deepSearch(lib, source.assetId)) {
              result = lib;
              resultImportsCount = count;
            }
          }
        }
        catch (e, s) {
          _log.fine('Error asset: "$assetId" for "${source.assetId}"', e, s);
        }
      }
    }
    return result;
  }

  bool _deepSearch(LibraryElement lib, AssetId target) {
    for (var exportLib in lib.exportedLibraries) {
      var sourceLib = exportLib.source;
      if ((sourceLib is AssetBasedSource && sourceLib.assetId == target)
          || _deepSearch(exportLib, target)
      ) {
        return true;
      }
    }
    return false;
  }

  Iterable<LibraryElement> _convertElementToLibrary(UsedImportedElements usedElements) {
     var libs = new Set<LibraryElement>();
     usedElements.prefixMap.values.expand((i)=>i).forEach((element) {
       var library = element.library;
       if (library != null &&
           library.isPublic &&
//           !library.isPrivate &&
//           !library.isDartCore &&
           !library.source.uri.toString().contains(':_')
       ) {
         libs.add(library);
       }
     });
     usedElements.elements.forEach((element) {
       var library = element.library;
       if (library != null &&
           library.isPublic &&
//           !library.isPrivate &&
//           !library.isDartCore &&
           !library.source.uri.toString().contains(':_')
       ) {
         libs.add(library);
       }
     });
     return libs;
  }

  void _showReport() {
    _log.info('--------------------------------');
    _log.info('Report: ');
    _log.info('--------------------------------');

    _log.info('Total old: ${_workResult.sourceNodesTotal} -> new: ${_workResult.optNodesTotal}');
    if (_workResult.topFile != null) {
      _log.info('Top issue file: ${_workResult.topFile} nodes: ${_workResult.topNodeFile}');
    }
    if (_workResult.maxOptFile != null) {
      _log.info('Best optimization file: ${_workResult.maxOptFile} delta: ${_workResult.maxOptDelta}');
    }
    _log.info('Average nodes: old: ${_workResult.sourceNodesTotal ~/ _workResult.fileCount} -> new: ${_workResult.optNodesTotal ~/ _workResult.fileCount}');
    _log.info('--------------------------------');
  }

}

class WorkResult {
  AssetId _topFile;
  int _topNodeFile = 0;
  AssetId _maxOptFile;
  int _maxOptDelta = 0;
  int _sourceNodesTotal = 0;
  int _optNodesTotal = 0;
  int _fileCount = 0;

  int get fileCount => _fileCount;

  AssetId get topFile => _topFile;

  int get topNodeFile => _topNodeFile;

  AssetId get maxOptFile => _maxOptFile;

  int get maxOptDelta => _maxOptDelta;

  int get sourceNodesTotal => _sourceNodesTotal;

  int get optNodesTotal => _optNodesTotal;

  void addStatisticFile(AssetId file, int sourceNode, int optNode) {
    _fileCount++;
    _sourceNodesTotal += sourceNode;
    _optNodesTotal += optNode;
    if (_topNodeFile < sourceNode) {
      _topNodeFile = sourceNode;
      _topFile = file;
    }
    var delta = sourceNode - optNode;
    if (_maxOptDelta < delta) {
      _maxOptDelta = delta;
      _maxOptFile = file;
    }
  }
}