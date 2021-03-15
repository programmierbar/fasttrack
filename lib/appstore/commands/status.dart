import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';

class AppStoreStatusCommand extends AppStoreCommand {
  final name = 'status';
  final description = 'Get the status of all app versions';

  AppStoreStatusCommand(AppStoreConfig config) : super(config);

  Future<void> run() async {
    final versions = Map.fromIterables(
      config.appIds.keys,
      await Future.wait(config.appIds.values.map((id) => client.getVersions(id))),
    );

    for (final entry in versions.entries) {
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
