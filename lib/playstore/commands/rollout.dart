import 'package:collection/collection.dart';
import 'package:fasttrack/playstore/commands/command.dart';
import 'package:fasttrack/playstore/config.dart';

class PlayStoreRolloutCommand extends PlayStoreCommand {
  final name = 'rollout';
  final description = '''
Update the rollout of app version

Available subcommands:
  update    Update the rollout fraction for an active release, e.g. update 0.2
  halt      Halts the rollout of the current version
  complete  Completes a release and rolls out the version to all users''';

  final checked = true;
  String get prompt => 'Do you want to $_action the rollout $version for ${appIds.join(',')} '
      '${_fraction != null ? 'to ${(_fraction! * 100).round()}%' : ''}?';

  PlayStoreRolloutCommand(PlayStoreConfig config) : super(config) {
    argParser.addOption(
      PlayStoreCommand.trackOption,
      abbr: 't',
      help: 'The track on which to update the release',
      allowed: ['production', 'beta', 'alpha', 'internal'],
      defaultsTo: 'production',
    );
    argParser.addCommand('update');
    argParser.addCommand('halt');
    argParser.addCommand('complete');
  }

  String get _action => argResults!.command!.name!;
  double? get _fraction => parseFraction(argResults!.command!.rest.first) ?? config.rollout;

  PlayStoreCommandTask setupTask() {
    return PlayStoreRolloutTask(
      version: version,
      track: track,
      action: _action,
      fraction: _fraction,
      dryRun: dryRun,
    );
  }
}

class PlayStoreRolloutTask extends PlayStoreCommandTask {
  final String? version;
  final String track;
  final String action;
  final double? fraction;
  final bool dryRun;

  PlayStoreRolloutTask({
    required this.version,
    required this.track,
    required this.action,
    required this.fraction,
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

    if (action == 'complete') {
      release.status = 'completed';
      release.userFraction = null;
    } else if (action == 'halt') {
      if (release.status == 'halted') {
        return warning('${release.name} is already paused');
      }
      release.status = 'halted';
    } else if (action == 'update') {
      if (fraction == null) {
        return error('You must specify a fraction when updating a release');
      }
      if (release.status == 'inProgress' && release.userFraction == fraction) {
        return warning('${release.name} is already at ${fraction! * 100}% rollout');
      }
      release.status = 'inProgress';
      release.userFraction = fraction;
    } else {
      return error('The specified action $action is not supported');
    }

    track.releases = [release];

    await api.update(track);
    await api.commit(validateOnly: dryRun);

    success('${release.name} update ${dryRun ? 'valid' : 'successful'}');
  }
}
