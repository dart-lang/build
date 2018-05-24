import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset/cache.dart';
import 'package:build_runner/src/environment/io_environment.dart';
import 'package:build_runner/src/import_optimizer/settings.dart';
import 'package:build_runner/src/import_optimizer/work_result.dart';
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
  final WorkResult _workResult;
  CachingAssetReader _reader;
  final ImportOptimizerSettings settings;

  ImportOptimizer(ImportOptimizerSettings settings): this.settings = settings, _workResult = new WorkResult(settings);

  optimizePackage(String package) async {
    _log.info("Optimization package: '$package'");
    var assets = (await io.reader.findAssets(new Glob('lib/**.dart'), package: package).toList()).map((item)=>item.toString())
        //.where((item)=>!item.contains('/demo') && !item.contains('/example'))
        .toList();
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
         final stat = _workResult.statistics[inputId];
         print('// FileName: "$inputId"  unique old: ${stat.sourceNode} -> new: ${stat.optNode}, agg old: ${stat.sourceAggNode} -> new: ${stat.optAggNode}');
         print(output);

         if (settings.applyImports) {
           final firstImport = lib.unit.directives.firstWhere((dir) => dir.keyword.keyword == Keyword.IMPORT);
           final lastImport = lib.unit.directives.lastWhere((dir) => dir.keyword.keyword == Keyword.IMPORT);

           _replaceImportsInFile(inputId.path, output, firstImport.beginToken.charOffset,
               lastImport.endToken.charOffset);
         }
       }
     } catch(e,st){
       _log.fine("Skip '$inputId'", e, st);
     }
   }

   void _replaceImportsInFile(String filename, String newImports, int fromOffset, int toOffset) {
     final fullname = path.join('.', filename);
     final str = new File(fullname).readAsStringSync();
     final res = new StringBuffer();
     res.write(str.substring(0, fromOffset));
     res.writeln(newImports);
     res.write(str.substring(toOffset+1).trimLeft());
     new File(fullname).writeAsStringSync(res.toString());
     _log.info("File '$fullname' patched!");
   }


   _parseLibraryStat(Iterable<LibraryElement> libImports){
     var imports = new Set<LibraryElement>();
     _parseLib(Iterable<LibraryElement> libImports) {
       for (var item in libImports) {
         _workResult.addStatisticLibrary(item);
         if (imports.add(item) && !item.isDartCore && !item.isInSdk) {
           _parseLib(item.importedLibraries);
           _parseLib(item.exportedLibraries);
         }
       }
     }
     _parseLib(libImports);
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
           if (settings.allowSrcImport){
             optLibrary = library;
           } else {
             optLibrary = await _getOptLibraryImport(library, resolver);
           }
         }
         outputImports.add(optLibrary);
       } else {
         outputImports.add(library);
       }

     }
     return outputImports;
   }

  int _getNodeCountAccumulate(Iterable<LibraryElement> libImports) {
    var sum = 0;
    for (var lib in  libImports){
      sum += _getNodeCount([lib]);
    }
    return sum;
  }

  String _generateImportText(AssetId inputId, LibraryElement sourceLibrary, Iterable<LibraryElement> libraries) {
    var sb = new StringBuffer();
    _parseLibraryStat(sourceLibrary.importedLibraries);
    var sourceAccNodeCount = _getNodeCountAccumulate(sourceLibrary.importedLibraries);
    var optAccNodeCount = _getNodeCountAccumulate(libraries);
    var sourceNodeCount = _getNodeCount(sourceLibrary.importedLibraries);
    var optNodeCount = _getNodeCount(libraries);
    _workResult.addStatisticFile(inputId, sourceNodeCount, optNodeCount, sourceAccNodeCount, optAccNodeCount);

    if (sourceAccNodeCount > optAccNodeCount || _hasDeprectatedAssets(sourceLibrary.importedLibraries) || settings.showImportNodes) {
      final directives = <_DirectiveInfo>[];
      for (final library in libraries) {
        final source = library.source;
        final importUrl = (source is AssetBasedSource)
            ? 'package:${source.assetId.package}${source.assetId.path.substring(3)}'
            : source.uri.toString();

        if (importUrl == 'dart:core') continue;

        final priority = getDirectivePriority(importUrl);
        var importString = "import '$importUrl';";
        if (settings.showImportNodes){
          importString += '// nodes: ${_getNodeCount([library])}';
        }
        directives
            .add(new _DirectiveInfo(priority, importUrl, importString));
      }

      directives.sort();

      _DirectivePriority currentPriority;
      for (final directiveInfo in directives) {
        if (currentPriority != directiveInfo.priority) {
          if (sb.length != 0) {
            sb.writeln();
          }
          currentPriority = directiveInfo.priority;
        }
        sb.writeln(directiveInfo.text);
      }
    }
    return sb.toString();
  }



  static _DirectivePriority getDirectivePriority(String uriContent) {
      if (uriContent.startsWith('dart:')) {
        return _DirectivePriority.IMPORT_SDK;
      } else if (uriContent.startsWith('package:')) {
        return _DirectivePriority.IMPORT_PKG;
      } else if (uriContent.contains('://')) {
        return _DirectivePriority.IMPORT_OTHER;
      }
      return _DirectivePriority.IMPORT_REL;
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
    _log.info('Report: ${new DateTime.now().toIso8601String()}');
    _log.info('--------------------------------');

    _log.info('Total aggregate old: ${_workResult.sourceAggNodesTotal} -> new: ${_workResult.optAggNodesTotal} (${-((1.0 - _workResult.optAggNodesTotal/_workResult.sourceAggNodesTotal)*100).truncate() }%)');
    _log.info('Total uniq old: ${_workResult.sourceNodesTotal} -> new: ${_workResult.optNodesTotal} (${-((1.0 - _workResult.optNodesTotal/_workResult.sourceNodesTotal)*100).truncate() }%)');
    if (_workResult.topFile != null) {
      _log.info('Top issue file: ${_workResult.topFile} nodes: ${_workResult.topNodeFile}');
    }
    if (_workResult.maxOptFile != null) {
      _log.info('Best optimization file: ${_workResult.maxOptFile} delta: ${_workResult.maxOptDelta}');
    }
    _log.info('Average nodes per file: old: ${_workResult.sourceNodesTotal ~/ _workResult.fileCount} -> new: ${_workResult.optNodesTotal ~/ _workResult.fileCount}');
    _log.info('--------------------------------');
    _log.info('Stat export over limit "${settings.limitExportsPerFile}>" :');
    _log.info(' ${'Exp COUNT'.padLeft(9)} | ${'USES'.padLeft(8)} | $AssetId');
    var packagesListExport = _workResult.statisticsPerExportOverLimit.keys.toList(growable: false);
    packagesListExport.sort((a,b){
      var bb = _workResult.statisticsPerExportOverLimit[b];
      var aa = _workResult.statisticsPerExportOverLimit[a];
      return (bb.exportCount * bb.uses).compareTo(aa.exportCount * aa.uses);
    });
    packagesListExport.forEach((item){
      final expStat = _workResult.statisticsPerExportOverLimit[item];
      _log.info(' ${expStat.exportCount.toString().padLeft(9)} | ${expStat.uses.toString().padLeft(8)} | $item');
    });
    _log.info('--------------------------------');
    _log.info('Stat import package in tree (${_workResult.statisticsPerPackages.length}):');
    _log.info(' COUNT    | Package');
    var packagesList = _workResult.statisticsPerPackages.keys.toList(growable: false);
    packagesList.sort((a,b){
      return _workResult.statisticsPerPackages[b].compareTo(_workResult.statisticsPerPackages[a]);
    });
    packagesList.forEach((package){
      final count = _workResult.statisticsPerPackages[package];
      _log.info(' ${count.toString().padLeft(8)} | $package ');
    });
    _log.info('--------------------------------');
  }


  bool _hasDeprectatedAssets(List<LibraryElement> importedLibraries) {
    return importedLibraries.any((library) {
      return library.hasDeprecated;
    });
  }

}

class _DirectiveInfo implements Comparable<_DirectiveInfo> {
  final _DirectivePriority priority;
  final String uri;
  final String text;

  _DirectiveInfo(this.priority, this.uri, this.text);

  @override
  int compareTo(_DirectiveInfo other) {
    if (priority == other.priority) {
      return _compareUri(uri, other.uri);
    }
    return priority.ordinal - other.priority.ordinal;
  }

  @override
  String toString() => '(priority=$priority; text=$text)';

  static int _compareUri(String a, String b) {
    final aList = _splitUri(a);
    final bList = _splitUri(b);
    int result;
    if ((result = aList[0].compareTo(bList[0])) != 0) return result;
    if ((result = aList[1].compareTo(bList[1])) != 0) return result;
    return 0;
  }

  /// Split the given [uri] like `package:some.name/and/path.dart` into a list
  /// like `[package:some.name, and/path.dart]`.
  static List<String> _splitUri(String uri) {
    final index = uri.indexOf('/');
    if (index == -1) {
      return <String>[uri, ''];
    }
    return <String>[uri.substring(0, index), uri.substring(index + 1)];
  }
}

class _DirectivePriority {
  static const IMPORT_SDK = const _DirectivePriority('IMPORT_SDK', 0);
  static const IMPORT_PKG = const _DirectivePriority('IMPORT_PKG', 1);
  static const IMPORT_OTHER = const _DirectivePriority('IMPORT_OTHER', 2);
  static const IMPORT_REL = const _DirectivePriority('IMPORT_REL', 3);
  static const EXPORT_SDK = const _DirectivePriority('EXPORT_SDK', 4);
  static const EXPORT_PKG = const _DirectivePriority('EXPORT_PKG', 5);
  static const EXPORT_OTHER = const _DirectivePriority('EXPORT_OTHER', 6);
  static const EXPORT_REL = const _DirectivePriority('EXPORT_REL', 7);
  static const PART = const _DirectivePriority('PART', 8);

  final String name;
  final int ordinal;

  const _DirectivePriority(this.name, this.ordinal);

  @override
  String toString() => name;
}
