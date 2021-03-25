// set release type -> manual | after_approval

import 'package:collection/collection.dart';
import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/appstore/connect_api/model/phased_release.dart';
import 'package:fasttrack/common/command.dart';

class AppStoreSubmitCommand extends AppStoreCommand {
  static const _buildOption = 'build';
  static const _manualFlag = 'manual';
  static const _phasedFlag = 'phased';
  static const _rejectFlag = 'reject';

  final name = 'submit';
  final description = 'Submit a app store version for review';

  AppStoreSubmitCommand(AppStoreConfig config) : super(config) {
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
      defaultsTo: true,
    );
    argParser.addFlag(
      _rejectFlag,
      abbr: 'r',
      help: 'Whether to reject the current version submission',
    );
  }

  AppStoreCommandTask setupTask() {
    return AppStoreSubmitTask(
        version: version,
        build: build,
        manual: getParam(_manualFlag),
        phased: getParam(_phasedFlag),
        reject: getParam(_rejectFlag));
  }

  String? get build => getParam(_buildOption) ?? context?.version.build;
}

class AppStoreSubmitTask extends AppStoreCommandTask {
  static const _pollInterval = Duration(seconds: 15);

  final String? version;
  final String? build;
  final bool manual;
  final bool phased;
  final bool reject;

  AppStoreSubmitTask({
    required this.version,
    required this.build,
    required this.manual,
    required this.phased,
    required this.reject,
  });

  Future<void> run() async {
    log('${this.version ?? 'release'} submit for review');
    var version = await _getVersion();

    final releaseType = manual ? ReleaseType.manual : ReleaseType.afterApproval;
    if (version.releaseType != releaseType) {
      version = await version.update(AppStoreVersionAttributes(releaseType: releaseType));
      log('updating release type $releaseType');
    }

    var phasedRelease = version.phasedRelease;
    if (phased && phasedRelease == null) {
      phasedRelease = await version.setPhasedRelease(AppStoreVersionPhasedReleaseAttributes(
        phasedReleaseState: PhasedReleaseState.inactive,
      ));
      log('added phased release');
    } else if (!phased && phasedRelease != null) {
      await phasedRelease.delete();
      log('removed phased release');
    }

    var build = version.build;
    if (build == null || build.version != this.build) {
      build = await _getBuild(version.versionString);
      if (!build.valid) {
        throw TaskException('The requested build is ${build.processingState.toString().toLowerCase()}');
      }
      await version.setBuild(build);
    }

    var submission = version.submission;
    if (!reject && submission == null) {
      submission = await version.addSubmission();
      success('${version.versionString} (${build.version}) submitted for review');
    } else if (submission != null) {
      if (!submission.canReject) {
        throw TaskException('${version.versionString} can not be unsubmitted anymore');
      }
      await submission.delete();
      success('${version.versionString} successfully unsubmitted');
    }
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
