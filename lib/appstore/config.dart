class AppStoreReleaseConfig {
  final bool phased;
  final bool manual;

  const AppStoreReleaseConfig({
    this.phased = true,
    this.manual = false,
  });

  AppStoreReleaseConfig.fromMap(Map<String, dynamic> map, [AppStoreReleaseConfig? base])
      : phased = map['phased'] ?? base?.phased ?? true,
        manual = map['manual'] ?? base?.manual ?? false;
}

class AppStoreAppConfig extends AppStoreReleaseConfig {
  final String id;
  final String appId;

  const AppStoreAppConfig({
    required this.id,
    required this.appId,
    bool phased = true,
    bool manual = false,
  });

  AppStoreAppConfig.fromMap(Map<String, dynamic> map, [AppStoreReleaseConfig? base])
      : id = map['id'],
        appId = map['appId'],
        super.fromMap(map, base);
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

  AppStoreCredentialsConfig.fromMap(Map<String, dynamic> map)
      : keyId = map['keyId'],
        issuerId = map['issuerId'],
        keyFile = map['keyFile'];
}

class AppStoreConfig {
  final AppStoreCredentialsConfig credentials;
  final AppStoreReleaseConfig? release;
  final List<AppStoreAppConfig> apps;

  const AppStoreConfig({
    required this.credentials,
    this.release,
    required this.apps,
  });

  AppStoreConfig.fromAppIds({required this.credentials, this.release, required Map<String, String> appIds})
      : apps = appIds.entries.map((entry) => AppStoreAppConfig(id: entry.key, appId: entry.value)).toList();

  factory AppStoreConfig.fromMap(Map<String, dynamic> map) {
    final credentials = AppStoreCredentialsConfig.fromMap(map['credentials']);
    final release = AppStoreReleaseConfig.fromMap(map['release']);
    final apps = (map['apps'] as List).map((item) => AppStoreAppConfig.fromMap(item, release)).toList();
    return AppStoreConfig(credentials: credentials, release: release, apps: apps);
  }

  Iterable<String> get ids => apps.map((app) => app.id);
}
