import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/playstore/config.dart';

class StoreConfig {
  final AppStoreConfig? appStore;
  final PlayStoreConfig? playStore;

  const StoreConfig({
    this.appStore,
    this.playStore,
  });
}
