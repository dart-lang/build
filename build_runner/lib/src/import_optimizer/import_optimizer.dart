import 'dart:async';

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset/cache.dart';
import 'package:build_runner/src/environment/io_environment.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart' as log show Logger;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
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
      var visitor = new ImportTypeCollectorVisitor(inputId);
      var ast = lib.unit;
      ast.visitChildren(visitor);
      var sb = new StringBuffer();
      sb.writeln('//--------------------------');
      sb.writeln('// FileName: "$inputId"');
      var sources = visitor._types.values.toSet();
      for (var source in sources ){
        if (source is AssetBasedSource){
          var assetId = source.assetId;
          var postMessage = '';
          // Local package
          if (assetId.package == inputId.package){
            postMessage = '/* local import */';
          } else if (source.assetId.path.contains('/src/')){
            assetId = await _getCorrectImportAssetId(source, resolver);
            postMessage = '/* \'${source.assetId}\' -> \'$assetId\' entry point*/';
          }
          sb.write("import 'package:${assetId.package}${assetId.path.substring(3)}'; $postMessage");
        } else {
          sb.write("import '${source.uri}';");
        }
        sb.writeln();
      }
      sb.writeln('//--------------------------');
      print(sb.toString());
    }
  }

  Future<AssetId> _getCorrectImportAssetId(AssetBasedSource source, Resolver resolver) async {
    var result = source.assetId;
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
            result = (lib.source as AssetBasedSource).assetId;
            break;
          }
        }
        catch (e, s) {
          _log.fine('Error asset: "${assetId}" for "${source.assetId}"', e, s);
        }
      }
    }
    return result;
  }


}


class ImportTypeCollectorVisitor extends GeneralizingAstVisitor<Object> {
  final _types = <DartType, Source>{};
  final AssetId currentAssetId;

  ImportTypeCollectorVisitor(this.currentAssetId);
  Map<DartType, Source> get collectedTypes => _types;
  @override
  Object visitTypeName(TypeName node){
    if (node.type.element != null && !node.type.element.isPrivate && node.type.element.library!= null && !node.type.element.library.isDartCore){
      var source = node.type.element.library.source;
      if (source is AssetBasedSource) {
        if (source.assetId != currentAssetId){
          _types.putIfAbsent(node.type, () => node.type.element.library.source);
        }
      } else {
        _types.putIfAbsent(node.type, () => node.type.element.library.source);
      }
    }
    return super.visitTypeName(node);
  }

//  @override
//  Object visitSimpleIdentifier(SimpleIdentifier node) {
//     return super.visitSimpleIdentifier(node);
//  }
}