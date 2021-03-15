import 'package:fasttrack/appstore/connect_api/token.dart';

class AppStoreConfig implements AppStoreConnectTokenConfig {
  final String keyId;
  final String issuerId;
  final String keyFile;
  final Map<String, String> appIds;

  const AppStoreConfig({
    required this.keyId,
    required this.issuerId,
    required this.keyFile,
    required this.appIds,
  });
}
