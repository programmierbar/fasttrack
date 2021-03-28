import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';

class AppStoreRolloutCommand extends AppStoreCommand {
  final name = 'rollout';
  final description = 'Update an version in phased release';

  AppStoreRolloutCommand(AppStoreConfig config) : super(config) {
    argParser.addCommand('start');
    argParser.addCommand('pause');
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
        ? await manager.getVersion(this.version!)
        : await manager.liveVersion();

    if (version == null) {
      return error('${this.version} not found');
    }

    if (version.appStoreState == AppStoreState.pendingDeveloperRelease) {
      // the app store connect api does not provide the 'appStoreVersionReleaseRequests'
      // endpoint. therefore we have to use a hacky workaround to set the release type
      // to scheduled and the release date to and date time in the past to switch the
      // app version from the pendingForDeveloperRelease to readyForSale state. see
      // https://github.com/fastlane/fastlane/discussions/18190#discussioncomment-492865
      await manager.updateReleaseType(
        version,
        releaseType: ReleaseType.scheduled,
        earliestReleaseDate: DateTime.now(),
      );

      version = await manager.awaitVersionInState(
        version: version.versionString,
        state: AppStoreState.readyForSale,
        log: log,
      );
    }

    if (version.phasedRelease == null) {
      return success('${this.version} rollout completed');
    }

    var state = PhasedReleaseState.active;
    if (action == 'paused') {
      state = PhasedReleaseState.paused;
    } else if (action == 'complete') {
      state = PhasedReleaseState.complete;
    }

    if (await manager.updateReleaseState(version, state)) {
      success('${this.version} rollout updated to ${state.toString().toLowerCase()}');
    } else {
      warning('${this.version} rollout already ${state.toString().toLowerCase()}');
    }
  }
}
