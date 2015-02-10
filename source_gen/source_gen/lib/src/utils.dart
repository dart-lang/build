library source_gen.utils;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:cli_util/cli_util.dart' as cli;
import 'package:path/path.dart' as p;

import 'io.dart';

bool matchAnnotation(Type annotationType, ElementAnnotation annotation) {
  var classMirror = reflectClass(annotationType);
  var classMirrorSymbol = classMirror.simpleName;

  var annTypeName = _annotationClassName(annotation);
  var annotationTypeSymbol = new Symbol(annTypeName);

  if (classMirrorSymbol != annotationTypeSymbol) {
    return false;
  }

  var annotationSource = annotation.element.source as FileBasedSource;

  var libOwner = classMirror.owner as LibraryMirror;

  Uri libraryUri;

  switch (libOwner.uri.scheme) {
    case 'file':
      libraryUri = libOwner.uri;
      break;
    case 'package':
      libraryUri = _fileUriFromPackageUri(libOwner.uri);
      break;
    default:
      throw new UnimplementedError(
          'We do not support scheme ${libOwner.uri.scheme}.');
  }

  return annotationSource.uri == libraryUri;
}

Uri _fileUriFromPackageUri(Uri libraryPackageUri) {
  assert(libraryPackageUri.scheme == 'package');
  var packageDir = _getPackageRoot();

  var fullLibraryPath = p.join(packageDir, libraryPackageUri.path);

  var file = new File(fullLibraryPath);

  assert(file.existsSync());

  var normalPath = file.resolveSymbolicLinksSync();

  return new Uri.file(normalPath);
}

String _getPackageRoot() {
  var dir = Platform.packageRoot;

  if (dir.isEmpty) {
    dir = p.join(p.current, 'packages');
  }

  assert(FileSystemEntity.isDirectorySync(dir));

  return dir;
}

String _annotationClassName(ElementAnnotation annotation) {
  var element = annotation.element;

  if (element is ConstructorElementImpl) {
    return element.returnType.name;
  } else {
    throw 'I cannot get the name for $annotation';
  }
}

/// [dartFiles] is a [Stream] of paths to [.dart] files.
Iterable<LibraryElement> getLibraryElements(
    List<String> dartFiles, AnalysisContext context) => dartFiles
    .map((path) => _getLibraryElement(path, context))
    .where((lib) => lib != null);

// may return `null` if [path] doesn't refer to a library.
LibraryElement _getLibraryElement(String path, AnalysisContext context) {
  Source source = new FileBasedSource.con1(new JavaFile(path));
  if (context.computeKindOf(source) == SourceKind.LIBRARY) {
    return context.computeLibraryElement(source);
  }
  return null;
}

/// [librarySearchPaths] is an optional list of relative paths to dart files
/// and directories.
Future<AnalysisContext> getAnalysisContextForProjectPath(String projectPath,
    {List<String> librarySearchPaths}) async {
  // TODO: fail more clearly if this...fails
  var sdkPath = cli.getSdkDir().path;

  JavaSystemIO.setProperty("com.google.dart.sdk", sdkPath);
  DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;

  var packagesPath = p.join(projectPath, 'packages');

  var packageDirectory = new JavaFile(packagesPath);

  // TODO(kevmoo): Can we get of one of these?
  var resolvers = [
    new DartUriResolver(sdk),
    new ResourceUriResolver(PhysicalResourceProvider.INSTANCE),
    new PackageUriResolver([packageDirectory])
  ];

  var context = AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = new SourceFactory(resolvers);

  var foundFiles = await getDartFiles(projectPath, searchList: librarySearchPaths);

  // ensures all libraries defined by the set of files are resolved
  getLibraryElements(foundFiles, context).toList();

  return context;
}

LibraryElement getLibraryElementForSourceFile(
        AnalysisContext context, String sourcePath) =>
    _getCompilationUnit(context, sourcePath).element.library;

CompilationUnit _getCompilationUnit(
    AnalysisContext context, String sourcePath) {
  Source source = new FileBasedSource.con1(new JavaFile(sourcePath));

  var librarySources = context.getLibrariesContaining(source);

  if (librarySources.length > 1) {
    throw new ArgumentError('Found more than one library for $sourcePath.');
  }

  LibraryElement libElement;
  if (librarySources.isEmpty) {
    libElement = context.computeLibraryElement(source);
  } else {
    libElement = context.computeLibraryElement(librarySources.single);
  }
  return context.resolveCompilationUnit(source, libElement);
}

String frieldlyNameForElement(Element element) {
  var friendlyName = element.displayName;

  if (friendlyName == null) {
    throw new ArgumentError(
        'Cannot get friendly name for $element - ${element.runtimeType}.');
  }

  var names = <String>[friendlyName];
  if (element is ClassElement) {
    names.insert(0, 'class');
    if (element.isAbstract) {
      names.insert(0, 'abstract');
    }
  }
  if (element is VariableElement) {
    names.insert(0, element.type.toString());

    if (element.isConst) {
      names.insert(0, 'const');
    }

    if (element.isFinal) {
      names.insert(0, 'final');
    }
  }

  return names.join(' ');
}

Iterable<Element> getElementsFromLibraryElement(LibraryElement unit) =>
    unit.units
        .expand((cu) => cu.unit.declarations)
        .expand((compUnitMember) => _getElements(compUnitMember));

Iterable<Element> _getElements(CompilationUnitMember member) {
  if (member is TopLevelVariableDeclaration) {
    return member.variables.variables.map((v) => v.element);
  }
  var element = member.element;

  if (element == null) {
    print([member, member.runtimeType, member.element]);
    throw new Exception('Could not find any elements for the provided unit.');
  }

  return [element];
}

String findPartOf(String source) {
  try {
    var unit = parseCompilationUnit(source);

    var partOf = unit.directives.firstWhere((d) => d is PartOfDirective,
        orElse: () => null);

    if (partOf == null) {
      return null;
    }

    var offset = partOf.offset;

    return source.substring(offset);
  } on AnalyzerErrorGroup catch (e) {
    return null;
  }
}

final _commentLineRegexp = new RegExp('(//.*|\w*)[\r\n]+');
