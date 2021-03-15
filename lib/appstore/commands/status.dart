import 'package:args/command_runner.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';

class AppStoreStatusCommand extends Command {
  final name = 'status';
  final description = 'Get the status of all app versions';

  AppStoreStatusCommand();

  Future<void> run() async {
    final config = AppStoreConfig(
      keyId: '47KUQ5A2CF',
      issuerId: '69a6de6f-9699-47e3-e053-5b8c7c11a4d1',
      keyFile: './credentials/AuthKey_47KUQ5A2CF.pem',
      appIds: {
        'de': '595098366',
        'en': '595558452',
        'fr': '596006531',
        'es': '598945891',
        'it': '598938741',
        'br': '814352052',
        'nl': '601316585',
        'ru': '598949838'
      },
    );

    final client = AppStoreConnectClient(config);
    final versions = await Future.wait(config.appIds.values.map((id) => client.getVersions(id)));

    final appVersions = Map.fromIterables(config.appIds.keys, versions);
    for (final entry in appVersions.entries) {
      for (final version in entry.value) {
        final parts = <dynamic?>[
          '${entry.key}:',
          version.name,
          if (version.build != null) //
            '(${version.build?.version})',
          '->',
          version.state,
          if (version.phasedRelease != null) //
            ...[enumToString(version.phasedRelease!.state), version.phasedRelease!.userFraction]
        ];
        print(parts.where((part) => part != null).join(' '));
      }
    }
  }
}
