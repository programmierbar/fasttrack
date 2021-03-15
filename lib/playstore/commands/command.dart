import 'package:args/command_runner.dart';
import 'package:fasttrack/playstore/client.dart';
import 'package:fasttrack/playstore/commands/status.dart';
import 'package:fasttrack/playstore/config.dart';

class PlayStoreCommandGroup extends Command {
  final String name = "playstore";
  final String description = "Bundles all PlayStore related commands";

  PlayStoreCommandGroup(PlayStoreConfig config) {
    addSubcommand(PlayStoreStatusCommand(config));
  }
}

abstract class PlayStoreCommand extends Command {
  final PlayStoreConfig config;
  PlayStoreApiClient? _client;

  PlayStoreCommand(this.config);

  Future<PlayStoreApiClient> getClient() async {
    if (_client == null) {
      _client = PlayStoreApiClient(config.keyFile);
      await _client!.connect();
    }
    return _client!;
  }
}
