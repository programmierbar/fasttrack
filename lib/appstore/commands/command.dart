import 'package:args/command_runner.dart' as args;
import 'package:fasttrack/appstore/commands/create.dart';
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
  final String description = 'Bundles all AppStore related commands';

  AppStoreCommandGroup(StoreConfig config) {
    final client = AppStoreConnectClient(config.appStore!);
    final loader = ReleaseNotesLoader(
      path: config.metadata!.dir,
      filePrefix: config.metadata!.filePrefix,
    );

    final commands = [
      AppStoreStatusCommand(),
      AppStoreCreateCommand(loader),
      AppStoreSubmitCommand(),
      AppStoreReleaseCommand()
    ];

    for (final command in commands) {
      command.config = config.appStore!;
      command.client = client;
      addSubcommand(command);
    }
  }
}

abstract class AppStoreCommand extends Command {
  static const appOption = 'app';
  static const versionOption = 'version';

  late final AppStoreConfig config;
  late final AppStoreConnectClient client;

  AppStoreCommand() {
    argParser.addOption(
      appOption,
      abbr: 'a',
      help: 'Run the command only for a set of apps. You can specify multiple apps by separating them by comma',
      //allowed: config.packageNames.keys,
    );
    argParser.addOption(
      versionOption,
      abbr: 'v',
      help: 'The version that should be promoted, updated or checked',
    );
  }

  Iterable<String> get appIds => getList<String>(appOption) ?? config.appIds.keys;
  String? get version => getParam(versionOption);

  Future<List<CommandTask>> setup() async {
    return appIds.map((id) {
      final task = setupTask();
      task.appId = id;
      task.api = AppStoreConnectApi(client, config.appIds[id]!);
      return task;
    }).toList();
  }

  AppStoreCommandTask setupTask();
}

abstract class AppStoreCommandTask extends CommandTask {
  late final AppStoreConnectApi api;
}
