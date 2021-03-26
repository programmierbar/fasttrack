import 'package:collection/collection.dart';
import 'package:fasttrack/playstore/commands/command.dart';
import 'package:fasttrack/playstore/config.dart';

class PlayStoreRolloutCommand extends PlayStoreCommand {
  final name = 'update';
  final description = 'Update a release version from on track to another';

  PlayStoreRolloutCommand(PlayStoreConfig config) : super(config) {
    argParser.addOption(
      PlayStoreCommand.trackOption,
      abbr: 't',
      help: 'The track on which to update the release',
      allowed: ['production', 'beta', 'alpha', 'internal'],
      defaultsTo: 'production',
    );
    argParser.addOption(
      PlayStoreCommand.rolloutOption,
      abbr: 'r',
      help: 'The fraction at which to rollout the version to the users',
    );
  }

  PlayStoreCommandTask setupTask() {
    return PlayStoreUpdateTask(
      version: version,
      track: track,
      rollout: rollout,
      dryRun: dryRun,
    );
  }
}

class PlayStoreUpdateTask extends PlayStoreCommandTask {
  final String? version;
  final String track;
  final double rollout;
  final bool dryRun;

  PlayStoreUpdateTask({
    required this.version,
    required this.track,
    required this.rollout,
    required this.dryRun,
  });

  Future<void> run() async {
    log('${version ?? 'release'} update ${dryRun ? 'validation' : ''}');
    final track = await api.get(track: this.track);

    final release = (version != null)
        ? track.releases?.firstWhereOrNull((release) => release.name == version)
        : track.releases?.firstWhereOrNull((release) => release.status == 'inProgress' || release.status == 'draft');

    if (release == null) {
      return error('${this.track} track has no release in rollout');
    }
    if (release.status == 'completed') {
      return warning('${release.name} is completed and can not be modified');
    }

    if (rollout == 1) {
      release.status = 'completed';
      release.userFraction = null;
    } else if (rollout > 0 && rollout < 1) {
      if (release.status == 'inProgress' && release.userFraction == rollout) {
        return warning('${release.name} is already at ${rollout * 100}% rollout');
      }
      release.status = 'inProgress';
      release.userFraction = rollout;
    } else {
      if (release.status == 'halted') {
        return warning('${release.name} is already halted');
      }
      release.status = 'halted';
    }

    track.releases = [release];

    await api.update(track);
    await api.commit(validateOnly: dryRun);

    success('${release.name} update ${dryRun ? 'valid' : 'successful'}');
  }
}
