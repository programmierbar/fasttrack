import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';

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
      reject: getParam(_rejectFlag),
    );
  }

  String? get _build => getParam(_buildOption) ?? context?.version.build;
  bool get _manual => getParam(_manualFlag) ?? store.release?.manual ?? true;
  bool get _phased => getParam(_phasedFlag) ?? store.release?.phased ?? true;
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
    final version = await manager.editVersion(this.version);

    final releaseType = manual ? ReleaseType.manual : ReleaseType.afterApproval;
    if (await manager.updateReleaseType(version, releaseType: releaseType)) {
      log('updated release type to ${releaseType.toString().toLowerCase()}');
    }

    if (await manager.updatePhasedRelease(version, phased: phased)) {
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

    if (await manager.updateSubmission(version, rejected: reject)) {
      log('${version.versionString} (${build.version}) ${reject ? 'rejected from review' : 'submitted for review'}');
    }
  }
}
