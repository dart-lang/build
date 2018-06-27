class ImportOptimizerSettings{
  final bool applyImports;
  final bool showImportNodes;
  final bool allowSrcImport;
  final int  limitExportsPerFile;
  final bool allowUnnecessaryDependenciesImports;

  ImportOptimizerSettings({this.applyImports = false, this.showImportNodes = false, this.allowSrcImport = false, this.limitExportsPerFile = 0, this.allowUnnecessaryDependenciesImports = false });
}