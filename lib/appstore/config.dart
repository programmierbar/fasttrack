import 'package:yaml/yaml.dart';

class AppStoreReleaseConfig {
  final bool phased;
  final bool manual;

  const AppStoreReleaseConfig({
    this.phased = true,
    this.manual = false,
  });

  AppStoreReleaseConfig.fromYaml(YamlMap map)
      : phased = map['phased'] ?? true,
        manual = map['manual'] ?? false;
}

class AppStoreAppConfig extends AppStoreReleaseConfig {
  final String id;
  final String appId;

  const AppStoreAppConfig({
    required this.id,
    required this.appId,
    bool phased = true,
    bool manual = false,
  }) : super(phased: phased, manual: manual);

  factory AppStoreAppConfig.fromYaml(String id, dynamic data, [AppStoreReleaseConfig? release]) {
    if (data is Map) {
      return AppStoreAppConfig(
        id: id,
        appId: data['appId'],
        phased: data['phased'] ?? release?.phased ?? true,
        manual: data['manual'] ?? release?.manual ?? false,
      );
    } else if (data is Object) {
      return AppStoreAppConfig(
        id: id,
        appId: data.toString(),
        phased: release?.phased ?? true,
        manual: release?.manual ?? false,
      );
    } else {
      throw Exception('The data for the app store config is neither an app id or an map');
    }
  }
}

class AppStoreCredentialsConfig {
  final String keyId;
  final String issuerId;
  final String keyFile;

  const AppStoreCredentialsConfig({
    required this.keyId,
    required this.issuerId,
    required this.keyFile,
  });

  AppStoreCredentialsConfig.fromYaml(YamlMap map)
      : keyId = map['keyId'],
        issuerId = map['issuerId'],
        keyFile = map['keyFile'];
}

class AppStoreConfig {
  final AppStoreCredentialsConfig credentials;
  final AppStoreReleaseConfig? release;
  final Map<String, AppStoreAppConfig> apps;

  const AppStoreConfig({
    required this.credentials,
    this.release,
    required this.apps,
  });

  factory AppStoreConfig.fromYaml(YamlMap map) {
    final credentials = AppStoreCredentialsConfig.fromYaml(map['credentials']);
    final release = map['release'] != null ? AppStoreReleaseConfig.fromYaml(map['release']) : null;
    final apps = (map['apps'] as YamlMap).map((key, value) {
      return MapEntry(key as String, AppStoreAppConfig.fromYaml(key, value, release));
    });

    return AppStoreConfig(credentials: credentials, release: release, apps: apps);
  }

  Iterable<String> get ids => apps.keys;
}
