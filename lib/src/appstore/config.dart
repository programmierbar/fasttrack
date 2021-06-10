import 'package:appstore_connect/appstore_connect.dart';
import 'package:fasttrack/src/common/config.dart';
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

  factory AppStoreAppConfig.fromAppId({
    required String id,
    required String appId,
    AppStoreReleaseConfig? release,
  }) {
    release ??= const AppStoreReleaseConfig();
    return AppStoreAppConfig(id: id, appId: appId, phased: release.phased, manual: release.manual);
  }

  factory AppStoreAppConfig.fromYaml({
    required String id,
    required dynamic data,
    AppStoreReleaseConfig? release,
  }) {
    release ??= AppStoreReleaseConfig();
    if (data is Map) {
      return AppStoreAppConfig(
        id: id,
        appId: data['appId'],
        phased: data['phased'] ?? release.phased,
        manual: data['manual'] ?? release.manual,
      );
    } else if (data is Object) {
      return AppStoreAppConfig(
        id: id,
        appId: data.toString(),
        phased: release.phased,
        manual: release.manual,
      );
    } else {
      throw Exception('The data for the App Store config is neither an app id or a map');
    }
  }
}

class AppStoreCredentialsConfig extends AppStoreConnectCredentials {
  AppStoreCredentialsConfig.fromYaml(YamlMap map)
      : super(
          keyId: map['keyId'],
          issuerId: map['issuerId'],
          keyFile: resolvePath(map['keyFile'], './fasttrack/credentials'),
        );
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
    if (!map.containsKey('credentials')) {
      throw Exception('The appstore section is missing the required credentials element');
    }

    final credentials = AppStoreCredentialsConfig.fromYaml(map['credentials']);
    final release = map['release'] != null ? AppStoreReleaseConfig.fromYaml(map['release']) : null;

    Map<String, AppStoreAppConfig> apps;
    if (map.containsKey('appId')) {
      apps = {DefaultAppId: AppStoreAppConfig(id: DefaultAppId, appId: map['appId'].toString())};
    } else if (map.containsKey('apps')) {
      apps = (map['apps'] as YamlMap).map((key, value) {
        return MapEntry(key as String, AppStoreAppConfig.fromYaml(id: key, data: value, release: release));
      });
    } else {
      throw Exception('The appstore section is missing either the appId or apps element');
    }

    return AppStoreConfig(credentials: credentials, release: release, apps: apps);
  }

  Iterable<String> get ids => apps.keys;
}
