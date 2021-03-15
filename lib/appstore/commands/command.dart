import 'package:args/command_runner.dart';
import 'package:fasttrack/appstore/commands/status.dart';

class AppStoreCommand extends Command {
  final String name = "appstore";
  final String description = "Bundles All AppStore related commands";

  AppStoreCommand() {
    addSubcommand(AppStoreStatusCommand());
  }
}
