import 'package:fasttrack/appstore/commands/command.dart';

class AppStoreReleaseCommand extends AppStoreCommand {
  final name = 'release';
  final description = 'Update an app store version in phased release';

  @override
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
