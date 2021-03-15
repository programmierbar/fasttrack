class AppStoreConfig {
  final String keyId;
  final String issuerId;
  final String keyFile;
  final Map<String, String> appIds;

  AppStoreConfig({
    required this.keyId,
    required this.issuerId,
    required this.keyFile,
    required this.appIds,
  });
}
