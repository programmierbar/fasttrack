import 'package:args/command_runner.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/client.dart';

class AppStoreStatusCommand extends Command {
  final name = 'status';
  final description = 'Get the status of all app versions';

  AppStoreStatusCommand();

  Future<void> run() async {
    final config = AppStoreConfig(
        keyId: '47KUQ5A2CF',
        issuerId: '69a6de6f-9699-47e3-e053-5b8c7c11a4d1',
        keyFile: './credentials/AuthKey_47KUQ5A2CF.pem',
        bundleIds: {
          'de': 'de.lotum.4pics1word',
          'en': 'de.lotum.4pics1worden',
          'fr': 'de.lotum.4pics1wordfr',
          'es': 'de.lotum.4pics1wordes',
          'it': 'de.lotum.4pics1wordit',
          'br': 'de.lotum.4pics1wordbr',
          'nl': 'de.lotum.4pics1wordnl',
          'ru': 'de.lotum.4pics1wordru'
        });

    final client = AppStoreConnectClient(config);
    final apps = await client.getApps(bundleIds: config.bundleIds.values.toList());

    for (final app in apps) {
      final version = app.liveVersion;
      if (version != null) {
        final parts = [
          '${app.bundleId}:',
          version.name,
          //'(${release.versionCodes?.join(', ')})',
          '->',
          version.state,
          //release.userFraction != null ? '${release.userFraction! * 100}%' : null,
        ];
        print(parts.where((part) => part != null).join(' '));
      }
    }
  }
}
