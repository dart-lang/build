import 'dart:io';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:tar/tar.dart';

class BuildResolversByteStore implements ByteStore {
  final Map<String, _ByteStoreEntry> _loadedEntries = {};

  /// Reads previously written entries from a [file].
  Future<void> readFromFile(File file) async {
    final archiveStream = file.openRead().transform(gzip.decoder);
    await TarReader.forEach(archiveStream, (entry) async {
      final builder = BytesBuilder();
      await entry.contents.forEach(builder.add);

      _loadedEntries[entry.name] = _ByteStoreEntry(builder.takeBytes());
    });
  }

  /// Serializes the in-memory entries of this byte store into a tar archive.
  Future<void> writeToFile(File file) {
    return Stream.fromIterable(_loadedEntries.entries)
        .map<TarEntry>(
            (e) => TarEntry.data(TarHeader(name: e.key), e.value.data))
        .transform(tarWriter)
        .transform(gzip.encoder)
        .pipe(file.openWrite());
  }

  @override
  Uint8List? get(String key) {
    return _loadedEntries[key]?.data;
  }

  @override
  Uint8List putGet(String key, Uint8List bytes) {
    _loadedEntries[key] = _ByteStoreEntry(bytes);
    return bytes;
  }

  @override
  void release(Iterable<String> keys) {
    for (final key in keys) {
      final entry = _loadedEntries[key];
      if (entry == null) continue;

      if (--entry.refCount == 0) {
        _loadedEntries.remove(key);
      }
    }
  }
}

class _ByteStoreEntry {
  int refCount = 1;
  final Uint8List data;

  _ByteStoreEntry(this.data);
}
