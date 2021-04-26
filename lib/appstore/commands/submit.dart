import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/manager.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/common/config.dart';

class AppStoreSubmitCommand extends AppStoreCommand {
  static const _buildOption = 'build';
  static const _manualFlag = 'manual';
  static const _phasedFlag = 'phased';
  static const _rejectFlag = 'reject';

  final name = 'submit';
  final description = 'Submit a app store version for review';
  final checked = true;

  String get prompt {
    return !_reject
        ? 'Do you want to submit $version with build $_build for ${appIds.join(',')} to review?'
        : 'Do you want to reject $version for ${appIds.join(',')}?';
  }

  AppStoreSubmitCommand(AppStoreConfig config, MetadataConfig? metadata) : super(config, metadata) {
    argParser.addOption(
      _buildOption,
      abbr: 'b',
      help: 'The build number to attach to the app store version',
    );
    argParser.addFlag(
      _manualFlag,
      abbr: 'm',
      help: 'Whether to manual release after approval',
      defaultsTo: null,
    );
    argParser.addFlag(
      _phasedFlag,
      abbr: 'p',
      help: 'Whether to do a phased release for the app store version',
      defaultsTo: null,
    );
    argParser.addFlag(
      _rejectFlag,
      abbr: 'r',
      help: 'Whether to reject the current version submission',
    );
  }

  AppStoreCommandTask setupTask() {
    return AppStoreSubmitTask(
      version: version!,
      build: _build,
      manual: _manual,
      phased: _phased,
      reject: _reject,
    );
  }

  String? get _build => getParam(_buildOption) ?? context?.version.build;
  bool get _manual => getParam(_manualFlag) ?? store.release?.manual ?? true;
  bool get _phased => getParam(_phasedFlag) ?? store.release?.phased ?? true;
  bool get _reject => getParam(_rejectFlag) ?? false;
}

class AppStoreSubmitTask extends AppStoreCommandTask {
  final String version;
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
    log('${this.version} submit for review');
    final version = await manager.editVersion() ?? //
        //await manager.liveVersion() ??
        await manager.createVersion(this.version);

    if (AppStoreState.rejectableStates.contains(version.appStoreState)) {
      // if the current editable version is already in pending developer release state,
      // we have to reject the version before we can attach a new build
      if (version.versionString != this.version) {
        return error('${version.versionString} in pending developer release, reject it using the --reject flag');
      } else if (reject) {
        await version.updateSubmission(rejected: true);
        return success('${this.version} rejected from pending developer release');
      } else {
        return success('${this.version} is already in pending developer release');
      }
    }

    if (version.versionString != this.version) {
      await version.updateVersionString(this.version);
      log('update editable version to ${this.version}');
    }

    final releaseType = manual ? ReleaseType.manual : ReleaseType.afterApproval;
    if (await version.updateReleaseType(releaseType: releaseType)) {
      log('updated release type to ${releaseType.toString().toLowerCase()}');
    }

    if (await version.updatePhasedRelease(phased: phased)) {
      log('updated phased release to $phased');
    }

    if (await manager.updateReleaseNotes(version)) {
      log('updated release notes');
    }

    var build = version.build;
    if (build == null || build.version != this.build) {
      build = await manager.getBuild(version: version.versionString, buildNumber: this.build, log: log);
      if (build == null) {
        return error('The requested build ${version.versionString} ${this.build} was not found');
      } else if (!build.valid) {
        return error('The requested build is ${build.processingState.toString().toLowerCase()}');
      }
      await version.setBuild(build);
    }

    if (await version.updateSubmission(rejected: reject)) {
      log('${version.versionString} (${build.version}) ${reject ? 'rejected from review' : 'submitted for review'}');
    }
  }
}
