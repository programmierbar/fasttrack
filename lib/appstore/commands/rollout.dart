import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/common/command.dart';

class AppStoreRolloutCommand extends AppStoreCommand {
  final name = 'rollout';
  final description = 'Update an version in phased release';

  AppStoreRolloutCommand(AppStoreConfig config) : super(config) {
    argParser.addCommand('pause');
    argParser.addCommand('resume');
    argParser.addCommand('complete');
  }

  PhasedReleaseState get _state {
    final state = argResults?.command?.name;
    switch (state) {
      case 'pause':
        return PhasedReleaseState.paused;
      case 'resume':
        return PhasedReleaseState.active;
      case 'complete':
        return PhasedReleaseState.complete;
      default:
        throw TaskException('unsupported state $state');
    }
  }

  AppStoreCommandTask setupTask() {
    return AppStoreRolloutTask(version: version, state: _state);
  }
}

class AppStoreRolloutTask extends AppStoreCommandTask {
  final String? version;
  final PhasedReleaseState state;

  AppStoreRolloutTask({
    required this.version,
    required this.state,
  });

  Future<void> run() async {
    log('${this.version} rollout update');

    final version = this.version != null //
        ? await manager.getVersion(this.version!)
        : await manager.liveVersion();

    if (version == null) {
      return error('${this.version} not found');
    }

    if (await manager.updateReleaseState(version, state)) {
      success('${this.version} rollout updated to ${state.toString().toLowerCase()}');
    } else {
      warning('${this.version} rollout already ${state.toString().toLowerCase()}');
    }
  }
}
