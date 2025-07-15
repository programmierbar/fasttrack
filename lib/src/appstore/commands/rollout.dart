import 'package:appstore_connect/appstore_connect.dart';
import 'package:fasttrack/src/appstore/client.dart';
import 'package:fasttrack/src/appstore/commands/command.dart';
import 'package:fasttrack/src/appstore/config.dart';

class AppStoreRolloutCommand extends AppStoreCommand {
  final name = 'rollout';
  final description = '''
Update a version in phased release.
  
Available subcommands:
  start     Start rollout of a version in pending developer release state
  halt      Halts the rollout of a version currently in phased release
  resume    Resumes a paused rollout
  complete  Completes a phased release and rolls out the version to all users''';

  final checked = true;
  String get prompt => 'Do you want to $_action the rollout for $version for ${appIds.join(',')}?';

  AppStoreRolloutCommand(AppStoreConfig config) : super(config) {
    argParser.addCommand('start');
    argParser.addCommand('halt');
    argParser.addCommand('resume');
    argParser.addCommand('complete');
  }

  String get _action {
    return argResults!.command!.name!;
  }

  AppStoreCommandTask setupTask() {
    return AppStoreRolloutTask(version: version, action: _action);
  }
}

class AppStoreRolloutTask extends AppStoreCommandTask {
  final String? version;
  final String action;

  AppStoreRolloutTask({
    required this.version,
    required this.action,
  });

  Future<void> run() async {
    log('${this.version} rollout update');

    var version = this.version != null //
        ? await client.getVersion(this.version!)
        : await client.liveVersion();

    if (version == null) {
      return error('${this.version} not found');
    }

    if (version.appVersionState == AppVersionState.pendingDeveloperRelease) {
      await version.requestRelease();

      version = await client.awaitVersionInState(
        version: version.versionString,
        state: AppVersionState.readyForDistribution,
        log: log,
      );
    }

    if (version.phasedRelease == null) {
      return success('${this.version} rollout completed');
    }

    var state = PhasedReleaseState.active;
    if (action == 'halt') {
      state = PhasedReleaseState.paused;
    } else if (action == 'complete') {
      state = PhasedReleaseState.complete;
    }

    if (await version.updateReleaseState(state)) {
      success('${this.version} rollout updated to ${state.toString().toLowerCase()}');
    } else {
      warning('${this.version} rollout already ${state.toString().toLowerCase()}');
    }
  }
}
