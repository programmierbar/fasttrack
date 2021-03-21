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
}

class MetadataConfig {
  final String dir;
  final String filePrefix;

  const MetadataConfig({required this.dir, this.filePrefix = 'release_notes_'});
}
