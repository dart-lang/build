// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, InternalAnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummaryUriResolver, InputPackagesResultProvider, SummaryDataStore;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;

import 'arg_parser.dart';

/// Builds an [AnalysisContext] backed by a summary SDK and package summary
/// files.
///
/// Any code which is not covered by the summaries must be resolvable through
/// [additionalResolvers].
AnalysisContext summaryAnalysisContext(
    SummaryOptions options, Iterable<UriResolver> additionalResolvers) {
  AnalysisEngine.instance.processRequiredPlugins();
  var sdk = new SummaryBasedDartSdk(options.sdkSummary, true);
  var sdkResolver = new DartUriResolver(sdk);

  var summaryData = new SummaryDataStore(options.summaryPaths)
    ..addBundle(null, sdk.bundle);
  var summaryResolver =
      new InSummaryUriResolver(PhysicalResourceProvider.INSTANCE, summaryData);

  var resolvers = <UriResolver>[]
    ..addAll(additionalResolvers)
    ..add(sdkResolver)
    ..add(summaryResolver);
  var sourceFactory = new SourceFactory(resolvers);

  var context = AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = sourceFactory;
  (context as AnalysisContextImpl).resultProvider =
      new InputPackagesResultProvider(
          context as InternalAnalysisContext, summaryData);

  return context;
}
