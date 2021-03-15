import 'package:args/command_runner.dart';
import 'package:fasttrack/appstore/commands/status.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/client.dart';

class AppStoreCommandGroup extends Command {
  final String name = "appstore";
  final String description = "Bundles all AppStore related commands";

  AppStoreCommandGroup(AppStoreConfig config) {
    addSubcommand(AppStoreStatusCommand(config));
  }
}

abstract class AppStoreCommand extends Command {
  final AppStoreConfig config;
  final AppStoreConnectClient client;

  AppStoreCommand(this.config) : client = AppStoreConnectClient(config);
}
