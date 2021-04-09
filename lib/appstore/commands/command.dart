import 'package:fasttrack/appstore/commands/prepare.dart';
import 'package:fasttrack/appstore/commands/rollout.dart';
import 'package:fasttrack/appstore/commands/status.dart';
import 'package:fasttrack/appstore/commands/submit.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/appstore/connect_api/manager.dart';
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/common/config.dart';
import 'package:fasttrack/common/context.dart';
import 'package:fasttrack/common/metadata.dart';

class AppStoreCommandGroup extends CommandGroup {
  final String name = 'appstore';
  final List<String> aliases = ['as'];
  final String description = 'Bundles all appstore related commands';

  AppStoreCommandGroup(StoreConfig config, Context? context) : super(context) {
    final store = config.appStore!;
    addCommands([
      AppStoreStatusCommand(store),
      AppStorePrepareCommand(store, config.metadata),
      AppStoreSubmitCommand(store),
      AppStoreRolloutCommand(store)
    ]);
  }
}

abstract class AppStoreCommand extends Command {
  final AppStoreConfig store;
  final MetadataConfig? metadata;

  AppStoreCommand(this.store, [this.metadata]) {
    argParser.addMultiOption(
      Command.appOption,
      abbr: 'a',
      help: 'Run the command only for a set of apps.',
      allowed: store.ids,
      defaultsTo: store.ids,
    );
  }

  Future<List<CommandTask>> setup() async {
    final client = AppStoreConnectClient(store.credentials);
    final loader = metadata != null //
        ? ReleaseNotesLoader(path: metadata!.dir, filePrefix: metadata!.filePrefix)
        : null;

    return appIds.map((id) {
      final app = store.apps[id]!;
      return setupTask()
        ..config = app
        ..manager = AppStoreVersionManager(
          AppStoreConnectApi(client, app.appId),
          loader,
        );
    }).toList();
  }

  AppStoreCommandTask setupTask();
}

abstract class AppStoreCommandTask extends CommandTask {
  late final AppStoreAppConfig config;
  late final AppStoreVersionManager manager;

  String get id => config.id;
}
