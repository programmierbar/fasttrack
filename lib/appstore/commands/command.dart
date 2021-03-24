import 'package:args/command_runner.dart' as args;
import 'package:fasttrack/appstore/commands/prepare.dart';
import 'package:fasttrack/appstore/commands/release.dart';
import 'package:fasttrack/appstore/commands/status.dart';
import 'package:fasttrack/appstore/commands/submit.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/common/config.dart';
import 'package:fasttrack/common/metadata.dart';

class AppStoreCommandGroup extends args.Command {
  final String name = 'appstore';
  final List<String> aliases = ['as'];
  final String description = 'Bundles all appstore related commands';

  AppStoreCommandGroup(StoreConfig config) {
    final storeConfig = config.appStore!;
    final releaseNotes = ReleaseNotesLoader(
      path: config.metadata!.dir,
      filePrefix: config.metadata!.filePrefix,
    );

    final commands = [
      AppStoreStatusCommand(storeConfig),
      AppStorePrepareCommand(storeConfig, releaseNotes),
      AppStoreSubmitCommand(storeConfig),
      AppStoreReleaseCommand(storeConfig)
    ];

    for (final command in commands) {
      addSubcommand(command);
    }
  }
}

abstract class AppStoreCommand extends Command {
  static const appOption = 'app';
  static const versionOption = 'version';

  final AppStoreConfig _config;

  AppStoreCommand(this._config) {
    argParser.addMultiOption(
      'app',
      abbr: 'a',
      help: 'Run the command only for a set of apps. You can specify multiple apps by separating them by comma',
      allowed: _config.ids,
      defaultsTo: _config.ids,
    );
    argParser.addOption(
      versionOption,
      abbr: 'v',
      help: 'The version that should be promoted, updated or checked',
    );
  }

  Iterable<String> get appIds => getList<String>(appOption)!;
  String? get version => getParam(versionOption);

  Future<List<CommandTask>> setup() async {
    final client = AppStoreConnectClient(_config.credentials);
    return appIds.map((id) {
      final app = _config.apps[id]!;
      return setupTask()
        ..config = app
        ..api = AppStoreConnectApi(client, app.appId);
    }).toList();
  }

  AppStoreCommandTask setupTask();
}

abstract class AppStoreCommandTask extends CommandTask {
  late final AppStoreAppConfig config;
  late final AppStoreConnectApi api;

  String get id => config.id;
}
