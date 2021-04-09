import 'dart:io';

import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/playstore/config.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class StoreConfig {
  static Future<StoreConfig> load(String path) async {
    final file = File('$path/fasttrack/config.yaml');
    if (!await file.exists()) {
      throw Exception('The fasttrack config file $path is missing');
    }

    final yaml = await file.readAsString();
    final data = loadYaml(yaml);

    return StoreConfig.fromYaml(data);
  }

  final MetadataConfig? metadata;
  final AppStoreConfig? appStore;
  final PlayStoreConfig? playStore;

  const StoreConfig({
    this.metadata,
    this.appStore,
    this.playStore,
  });

  StoreConfig.fromYaml(YamlMap map)
      : metadata = map['metadata'] != null ? MetadataConfig.fromMap(map['metadata']) : null,
        appStore = map['appStore'] != null ? AppStoreConfig.fromYaml(map['appStore']) : null,
        playStore = map['playStore'] != null ? PlayStoreConfig.fromYaml(map['playStore']) : null;
}

class MetadataConfig {
  final String dir;
  final String filePrefix;

  const MetadataConfig({required this.dir, this.filePrefix = 'release_notes_'});

  MetadataConfig.fromMap(YamlMap map)
      : dir = map['dir'],
        filePrefix = map['filePrefix'] ?? 'release_notes_';
}

String resolvePath(String path, String root) {
  return path.startsWith(root) ? path : join(root, path);
}
