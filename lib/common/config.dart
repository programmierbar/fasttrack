import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/playstore/config.dart';

class StoreConfig {
  final MetadataConfig? metadata;
  final AppStoreConfig? appStore;
  final PlayStoreConfig? playStore;

  const StoreConfig({
    this.metadata,
    this.appStore,
    this.playStore,
  });

  StoreConfig.fromMap(Map<String, dynamic> map)
      : metadata = map.containsKey('metadata') ? MetadataConfig.fromMap(map['metadata']) : null,
        appStore = map.containsKey('appStore') ? AppStoreConfig.fromMap(map['appStore']) : null,
        playStore = map.containsKey('playStore') ? PlayStoreConfig.fromMap(map['playStore']) : null;
}

class MetadataConfig {
  final String dir;
  final String filePrefix;

  const MetadataConfig({required this.dir, this.filePrefix = 'release_notes_'});
  MetadataConfig.fromMap(Map<String, dynamic> map)
      : dir = map['dir'],
        filePrefix = map['filePrefix'] ?? 'release_notes_';
}
