class AppStoreConfig {
  final String keyId;
  final String issuerId;
  final String keyFile;
  final Map<String, String> bundleIds;

  AppStoreConfig({
    required this.keyId,
    required this.issuerId,
    required this.keyFile,
    required this.bundleIds,
  });
}
