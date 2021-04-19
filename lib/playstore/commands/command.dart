import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/common/context.dart';
import 'package:fasttrack/playstore/client.dart';
import 'package:fasttrack/playstore/commands/promote.dart';
import 'package:fasttrack/playstore/commands/rollout.dart';
import 'package:fasttrack/playstore/commands/status.dart';
import 'package:fasttrack/playstore/config.dart';

class PlayStoreCommandGroup extends CommandGroup {
  final String name = 'playstore';
  final List<String> aliases = ['ps'];
  final String description = 'Bundles all Play Store related commands';

  PlayStoreCommandGroup(PlayStoreConfig config, Context? context) : super(context) {
    addCommands([
      PlayStoreStatusCommand(config),
      PlayStorePromoteCommand(config),
      PlayStoreRolloutCommand(config),
    ]);
  }
}

abstract class PlayStoreCommand extends Command {
  static const trackOption = 'track';
  static const _dryRunFlag = 'dry-run';

  final PlayStoreConfig config;

  PlayStoreCommand(this.config) {
    argParser.addMultiOption(
      Command.appOption,
      abbr: 'a',
      help: 'Run the command only for a set of apps. You can specify multiple apps by separating them by comma',
      allowed: config.ids,
      defaultsTo: config.ids,
    );
    argParser.addFlag(
      _dryRunFlag,
      abbr: 'd',
      help: 'Whether to only validate the promotion',
    );
  }

  String get track => getParam(trackOption);
  bool get dryRun => getParam(_dryRunFlag);

  Future<List<CommandTask>> setup() async {
    final client = PlayStoreApiClient(config.keyFile);
    await client.connect();

    return appIds.map((id) {
      final app = config.apps[id]!;
      return setupTask()
        ..config = app
        ..api = client.getTrackApi(packageName: app.appId);
    }).toList();
  }

  PlayStoreCommandTask setupTask();
}

abstract class PlayStoreCommandTask extends CommandTask {
  late final PlayStoreAppConfig config;
  late final PlayStoreTrackApi api;

  String get id => config.id;
}

double? parseFraction(String? value) {
  if (value is String) {
    if (value.contains('%')) {
      return double.parse(value.replaceAll('%', '')) / 100;
    } else {
      return double.parse(value);
    }
  }
  return value;
}
