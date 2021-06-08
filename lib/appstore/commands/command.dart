import 'package:appstore_connect/appstore_connect.dart';
import 'package:fasttrack/appstore/client.dart';
import 'package:fasttrack/appstore/commands/prepare.dart';
import 'package:fasttrack/appstore/commands/rollout.dart';
import 'package:fasttrack/appstore/commands/status.dart';
import 'package:fasttrack/appstore/commands/submit.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/common/config.dart';
import 'package:fasttrack/common/context.dart';
import 'package:fasttrack/common/metadata.dart';

class AppStoreCommandGroup extends CommandGroup {
  final String name = 'appstore';
  final List<String> aliases = ['as'];
  final String description = 'Bundles all App Store related commands';

  AppStoreCommandGroup(AppStoreConfig store, MetadataConfig? metadata, Context? context) : super(context) {
    addCommands([
      AppStoreStatusCommand(store),
      AppStorePrepareCommand(store, metadata),
      AppStoreSubmitCommand(store, metadata),
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
        ..client = AppStoreApiClient(
          AppStoreConnectApi(client, app.appId),
          loader,
        );
    }).toList();
  }

  AppStoreCommandTask setupTask();
}

abstract class AppStoreCommandTask extends CommandTask {
  late final AppStoreAppConfig config;
  late final AppStoreApiClient client;

  String get id => config.id;
}
