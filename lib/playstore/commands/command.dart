import 'package:args/command_runner.dart' as args;
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/playstore/client.dart';
import 'package:fasttrack/playstore/commands/promote.dart';
import 'package:fasttrack/playstore/commands/status.dart';
import 'package:fasttrack/playstore/commands/update.dart';
import 'package:fasttrack/playstore/config.dart';

class PlayStoreCommandGroup extends args.Command {
  final String name = "playstore";
  final String description = "Bundles all play store related commands";

  PlayStoreCommandGroup(PlayStoreConfig config) {
    addSubcommand(PlayStoreStatusCommand(config));
    addSubcommand(PlayStorePromoteCommand(config));
    addSubcommand(PlayStoreUpdateCommand(config));
  }
}

abstract class PlayStoreCommand extends Command {
  static const appOption = 'app';
  static const versionOption = 'version';
  static const trackOption = 'track';
  static const rolloutOption = 'rollout';

  final PlayStoreConfig config;
  PlayStoreApiClient? _client;

  PlayStoreCommand(this.config) {
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

  Iterable<String> get appIds => getList<String>(appOption) ?? config.packageNames.keys;
  String? get version => getParam(versionOption);
  String get track => getParam(trackOption);

  double get rollout {
    final value = getParam(rolloutOption);
    if (value is String) {
      if (value.contains('%')) {
        return double.parse(value.replaceAll('%', '')) / 100;
      } else {
        return double.parse(value);
      }
    } else {
      return value ?? 0;
    }
  }

  Future<List<CommandTask>> setup() async {
    final client = await getClient();
    return appIds.map((id) {
      final task = setupTask();
      task.appId = id;
      task.api = client.getTrackApi(packageName: config.packageNames[id]!);
      return task;
    }).toList();
  }

  PlayStoreCommandTask setupTask();

  Future<PlayStoreApiClient> getClient() async {
    if (_client == null) {
      _client = PlayStoreApiClient(config.keyFile);
      await _client!.connect();
    }
    return _client!;
  }
}

abstract class PlayStoreCommandTask extends CommandTask {
  late final PlayStoreTrackApi api;
}
