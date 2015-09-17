// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.results;

enum GenerationResultKind { noChangesOrLibraries, noLibrariesFound, okay }

class GenerationResult {
  final GenerationResultKind kind;
  final String message;
  final List<LibraryGenerationResult> results;

  const GenerationResult.noChangesOrLibraries()
      : kind = GenerationResultKind.noChangesOrLibraries,
        message = 'changeFilePaths and librarySearchPaths are empty.',
        results = const <LibraryGenerationResult>[];

  GenerationResult.noLibrariesFound(Iterable<String> changeFilePaths)
      : kind = GenerationResultKind.noLibrariesFound,
        message = "No libraries found for provided paths:\n"
            "  ${changeFilePaths.map((p) => "$p").join(', ')}\n"
            "They may not be in the search path.",
        results = const <LibraryGenerationResult>[];

  GenerationResult.okay(Iterable<LibraryGenerationResult> results)
      : this.kind = GenerationResultKind.okay,
        this.message = 'Generated libraries: ${results.join(', ')}',
        this.results = new List.unmodifiable(results);

  String toString() => message;
}

enum LibraryGenerationResultKind { created, updated, noop, noChange, deleted }

class LibraryGenerationResult {
  final LibraryGenerationResultKind kind;
  final String generatedFilePath;

  const LibraryGenerationResult.noop()
      : this.kind = LibraryGenerationResultKind.noop,
        this.generatedFilePath = null;

  const LibraryGenerationResult.created(this.generatedFilePath)
      : kind = LibraryGenerationResultKind.created;
  const LibraryGenerationResult.updated(this.generatedFilePath)
      : kind = LibraryGenerationResultKind.updated;
  const LibraryGenerationResult.noChange(this.generatedFilePath)
      : kind = LibraryGenerationResultKind.noChange;
  const LibraryGenerationResult.deleted(this.generatedFilePath)
      : kind = LibraryGenerationResultKind.deleted;

  @override
  String toString() => '$kind - $generatedFilePath';

  @override
  bool operator ==(other) => other is LibraryGenerationResult &&
      other.kind == kind &&
      other.generatedFilePath == generatedFilePath;
}
