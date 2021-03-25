import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/common/config.dart';

class AppStorePrepareCommand extends AppStoreCommand {
  final name = 'prepare';
  final description = '''Prepare new app store version.
  
This will either create a new version, if no editable version is available,
or update the current editable version with the new version string''';

  AppStorePrepareCommand(AppStoreConfig store, MetadataConfig? metadata) : super(store, metadata);

  AppStoreCommandTask setupTask() {
    if (version == null) {
      throw TaskException('version param is missing');
    }
    return AppStorePrepareTask(version: version!);
  }
}

class AppStorePrepareTask extends AppStoreCommandTask {
  final String version;

  AppStorePrepareTask({required this.version});

  Future<void> run() async {
    log('${this.version} preparation');
    final version = await manager.editVersion(this.version);
    await manager.updateReleaseNotes(version);
    success('${this.version} preparation completed');
  }
}
