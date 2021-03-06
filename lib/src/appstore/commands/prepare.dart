import 'package:fasttrack/src/appstore/client.dart';
import 'package:fasttrack/src/appstore/commands/command.dart';
import 'package:fasttrack/src/appstore/config.dart';
import 'package:fasttrack/src/common/command.dart';
import 'package:fasttrack/src/common/config.dart';

class AppStorePrepareCommand extends AppStoreCommand {
  final name = 'prepare';
  final description = '''Prepare a new App Store version.
  
This will either create a new version, if no editable version is available
or update the current editable version with the new version string''';

  final checked = true;
  String get prompt => 'Do you want to create the App Store version $version for ${appIds.join(',')}?';

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
    final version = await client.editVersion() ?? await client.createVersion(this.version);
    if (version.versionString != this.version) {
      await version.updateVersionString(this.version);
    }
    await client.updateReleaseNotes(version);
    success('${this.version} preparation completed');
  }
}
