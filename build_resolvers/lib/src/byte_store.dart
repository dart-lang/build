import 'dart:io';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:collection/collection.dart';
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
    const maxSize = 1024 * 1024 * 512; // 512 MiB
    var size = 0;

    // Persist the last recently used entries until we reach the maximum file
    // size.
    final entries = _loadedEntries.entries
        .sortedBy<DateTime>((e) => e.value.lastAccess)
        .reversed
        .takeWhile((entry) {
      size += entry.value.data.length;
      return size < maxSize;
    });

    return Stream.fromIterable(entries)
        .map<TarEntry>(
            (e) => TarEntry.data(TarHeader(name: e.key), e.value.data))
        .transform(tarWriter)
        .transform(gzip.encoder)
        .pipe(file.openWrite());
  }

  @override
  Uint8List? get(String key) {
    final entry = _loadedEntries[key];
    if (entry != null) {
      entry.lastAccess = DateTime.now();
      return entry.data;
    } else {
      return null;
    }
  }

  @override
  Uint8List putGet(String key, Uint8List bytes) {
    _loadedEntries[key] = _ByteStoreEntry(bytes);
    return bytes;
  }

  @override
  void release(Iterable<String> keys) {}
}

class _ByteStoreEntry {
  DateTime lastAccess = DateTime.now();

  Uint8List data;

  _ByteStoreEntry(this.data);
}
