import 'dart:io';

class ReleaseNotesLoader {
  final String path;
  final String filePrefix;

  ReleaseNotesLoader({required this.path, this.filePrefix = 'release_notes_'});

  Future<Map<String, String>> load() async {
    final directory = Directory(path);
    final contents = <String, Future<String>>{};

    await for (final entity in directory.list()) {
      if (entity is File) {
        final fileName = entity.path.substring(entity.path.lastIndexOf('/') + 1);
        if (fileName.startsWith(filePrefix)) {
          final locale = fileName.substring(0, fileName.indexOf('.')).replaceFirst(filePrefix, '');
          contents[locale] = entity.readAsString();
        }
      }
    }

    return Map.fromIterables(contents.keys, await Future.wait(contents.values));
  }
}
