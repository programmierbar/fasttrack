import 'package:fasttrack/src/common/config.dart';
import 'package:yaml/yaml.dart';

class PlayStoreReleaseConfig {
  final double rollout;

  const PlayStoreReleaseConfig({this.rollout = 1});
  PlayStoreReleaseConfig.fromYaml(YamlMap map, [PlayStoreReleaseConfig? base])
      : rollout = map['rollout'] ?? base?.rollout ?? 1;
}

class PlayStoreAppConfig extends PlayStoreReleaseConfig {
  final String id;
  final String packageName;

  const PlayStoreAppConfig({required this.id, required this.packageName, double rollout = 1}) : super(rollout: rollout);

  factory PlayStoreAppConfig.fromYaml(String id, dynamic data, [PlayStoreReleaseConfig? release]) {
    if (data is Map) {
      return PlayStoreAppConfig(
          id: id, packageName: data['packageName'], rollout: data['rollout'] ?? release?.rollout ?? 1);
    } else if (data is String) {
      return PlayStoreAppConfig(id: id, packageName: data, rollout: release?.rollout ?? 1);
    } else {
      throw Exception('The data for a Play Store app is not an app id or map');
    }
  }
}

class PlayStoreConfig extends PlayStoreReleaseConfig {
  final String keyFile;
  final Map<String, PlayStoreAppConfig> apps;

  const PlayStoreConfig({
    required this.keyFile,
    double rollout = 1,
    required this.apps,
  }) : super(rollout: rollout);

  factory PlayStoreConfig.fromYaml(YamlMap yaml) {
    if (!yaml.containsKey('keyFile')) {
      throw Exception('The playstore section is missing the required keyFile element');
    }

    final keyFile = resolvePath(yaml['keyFile'], './fasttrack/credentials');
    final release = PlayStoreReleaseConfig.fromYaml(yaml);

    Map<String, PlayStoreAppConfig> apps;
    if (yaml.containsKey('packageName')) {
      apps = {
        DefaultAppId: PlayStoreAppConfig(id: DefaultAppId, packageName: yaml['packageName'], rollout: release.rollout)
      };
    } else if (yaml.containsKey('apps')) {
      apps = (yaml['apps'] as Map).map((key, value) {
        return MapEntry(key as String, PlayStoreAppConfig.fromYaml(key, value, release));
      });
    } else {
      throw Exception('The playstore section is missing either the packageName or apps element');
    }

    return PlayStoreConfig(keyFile: keyFile, rollout: release.rollout, apps: apps);
  }

  Iterable<String> get ids => apps.keys;
}
