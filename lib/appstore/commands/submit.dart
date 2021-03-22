// set release type -> manual | after_approval

import 'package:collection/collection.dart';
import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/common/extension.dart';

class AppStoreSubmitCommand extends AppStoreCommand {
  static const _buildOption = 'build';
  static const _manualFlag = 'manual';
  static const _phasedFlag = 'phased';

  final name = 'submit';
  final description = 'Submit a app store version for review';

  AppStoreSubmitCommand() {
    argParser.addOption(
      _buildOption,
      abbr: 'b',
      help: 'The build number to attach to the app store version',
    );
    argParser.addFlag(
      _manualFlag,
      abbr: 'm',
      help: 'Whether to manual release after approval',
    );
    argParser.addFlag(
      _phasedFlag,
      abbr: 'p',
      help: 'Whether to do a phased release for the app store version',
    );
  }

  AppStoreCommandTask setupTask() {
    return AppStoreSubmitTask(
      version: version,
      build: getParam(_buildOption),
      manual: getParam(_manualFlag),
      phased: getParam(_phasedFlag),
    );
  }
}

class AppStoreSubmitTask extends AppStoreCommandTask {
  static const _pollInterval = Duration(seconds: 15);

  final String? version;
  final String? build;
  final bool manual;
  final bool phased;

  AppStoreSubmitTask({
    required this.version,
    required this.build,
    required this.manual,
    required this.phased,
  });

  Future<void> run() async {
    final version = await _getVersion();

    final build = await _getBuild(version.versionString);
    if (!build.valid) {
      throw TaskException('The requested build is ${enumToString(build.processingState)}');
    }

    await version.attachBuild(build);
    final temp = true;
  }

  Future<AppStoreVersion> _getVersion() async {
    final versions = await api.getVersions(
      versions: version != null ? [version!] : null,
      states: version == null ? AppStoreState.editStates : null,
    );
    if (versions.isEmpty) {
      throw TaskException('No version $version or in edit state was found');
    }
    return versions.first;
  }

  Future<Build> _getBuild(String version) async {
    final build = (await api.getBuilds(version: version, buildNumber: this.build)).firstOrNull;
    if (build != null && build.processed) {
      return build;
    }

    log('Waiting for build version $version ($build} to be processed');
    final startTime = DateTime.now();

    while (true) {
      await Future.delayed(_pollInterval);
      final duration = DateTime.now().difference(startTime);

      log('Waiting for build $version (${this.build}) to be processed for $duration');
      final build = (await api.getBuilds(version: version, buildNumber: this.build)).firstOrNull;
      if (build != null && build.processed) {
        return build;
      }
    }
  }
}
