class PlayStoreReleaseConfig {
  final double userFraction;

  const PlayStoreReleaseConfig({this.userFraction = 0.1});
  PlayStoreReleaseConfig.fromMap(Map<String, dynamic> map, [PlayStoreReleaseConfig? base])
      : userFraction = map['userFraction'] ?? base?.userFraction ?? 0.1;
}

class PlayStoreAppConfig extends PlayStoreReleaseConfig {
  final String id;
  final String packageName;

  const PlayStoreAppConfig({required this.id, required this.packageName, double userFraction = 0.1})
      : super(userFraction: userFraction);

  PlayStoreAppConfig.fromMap(Map<String, dynamic> map, [PlayStoreReleaseConfig? base])
      : id = map['id'],
        packageName = map['packageName'],
        super.fromMap(map, base);
}

class PlayStoreConfig extends PlayStoreReleaseConfig {
  final String keyFile;
  final List<PlayStoreAppConfig> apps;

  const PlayStoreConfig({
    required this.keyFile,
    double userFraction = 0.1,
    required this.apps,
  }) : super(userFraction: userFraction);

  PlayStoreConfig.fromPackageNames({
    required this.keyFile,
    double userFraction = 0.1,
    required Map<String, String> packageNames,
  }) : apps = packageNames.entries.map((entry) => PlayStoreAppConfig(id: entry.key, packageName: entry.value)).toList();

  factory PlayStoreConfig.fromMap(Map<String, dynamic> map) {
    final release = PlayStoreReleaseConfig.fromMap(map);
    return PlayStoreConfig(
      keyFile: map['keyFile'],
      userFraction: release.userFraction,
      apps: (map['apps'] as List).map((item) => PlayStoreAppConfig.fromMap(map, release)).toList(),
    );
  }

  Iterable<String> get appIds => apps.map((app) => app.id);
}
