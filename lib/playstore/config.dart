import 'package:yaml/yaml.dart';

class PlayStoreReleaseConfig {
  final double rollout;

  const PlayStoreReleaseConfig({this.rollout = 1});
  PlayStoreReleaseConfig.fromYaml(YamlMap map, [PlayStoreReleaseConfig? base])
      : rollout = map['rollout'] ?? base?.rollout ?? 1;
}

class PlayStoreAppConfig extends PlayStoreReleaseConfig {
  final String id;
  final String appId;

  const PlayStoreAppConfig({required this.id, required this.appId, double rollout = 1}) : super(rollout: rollout);

  factory PlayStoreAppConfig.fromYaml(String id, dynamic data, [PlayStoreReleaseConfig? release]) {
    if (data is Map) {
      return PlayStoreAppConfig(id: id, appId: data['appId'], rollout: data['rollout'] ?? release?.rollout ?? 1);
    } else if (data is String) {
      return PlayStoreAppConfig(id: id, appId: data, rollout: release?.rollout ?? 1);
    } else {
      throw Exception('The data for an play store app is not an app id oder map');
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
    final release = PlayStoreReleaseConfig.fromYaml(yaml);
    return PlayStoreConfig(
      keyFile: yaml['keyFile'],
      rollout: release.rollout,
      apps: (yaml['apps'] as Map).map((key, value) {
        return MapEntry(key as String, PlayStoreAppConfig.fromYaml(key, value, release));
      }),
    );
  }

  Iterable<String> get ids => apps.keys;
}
