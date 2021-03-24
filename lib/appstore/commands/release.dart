import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';

class AppStoreReleaseCommand extends AppStoreCommand {
  final name = 'release';
  final description = 'Update an app store version in phased release';

  AppStoreReleaseCommand(AppStoreConfig config) : super(config);

  AppStoreCommandTask setupTask() {
    return AppStoreReleaseTask();
  }
}

class AppStoreReleaseTask extends AppStoreCommandTask {
  Future<void> run() {
    // TODO: implement run
    throw UnimplementedError();
  }
}
