import 'package:collection/collection.dart';
import 'package:fasttrack/src/playstore/commands/command.dart';
import 'package:fasttrack/src/playstore/config.dart';
import 'package:googleapis/androidpublisher/v3.dart';

class PlayStorePromoteCommand extends PlayStoreCommand {
  static const _toOption = 'to';
  static const _rolloutOption = 'rollout';

  final name = 'promote';
  final description = 'Promote a release version from one track to another';
  final checked = true;

  String get prompt {
    return 'Do you want to promote $version from $track to $_to for ${appIds.join(',')} and roll it out '
        '${_rollout == 1 ? 'completely' : _rollout == 0 ? 'as draft' : 'to ${(_rollout * 100).round()}%'}?';
  }

  PlayStorePromoteCommand(PlayStoreConfig config) : super(config) {
    argParser.addOption(
      PlayStoreCommand.trackOption,
      abbr: 't',
      help: 'The track to promote the version from',
      allowed: ['beta', 'alpha', 'internal'],
      defaultsTo: 'internal',
    );
    argParser.addOption(
      _toOption,
      help: 'The track to promote the version to',
      allowed: ['production', 'beta', 'alpha'],
      defaultsTo: 'production',
    );
    argParser.addOption(
      _rolloutOption,
      abbr: 'r',
      help: 'The fraction at which to rollout the version to the users',
    );
  }

  String get _to => getParam(_toOption);
  double get _rollout => parseFraction(getParam(_rolloutOption)) ?? config.rollout;

  PlayStoreCommandTask setupTask() {
    return PlayStorePromoteTask(
      version: version,
      track: track,
      to: _to,
      rollout: _rollout,
      dryRun: dryRun,
    );
  }
}

class PlayStorePromoteTask extends PlayStoreCommandTask {
  final String? version;
  final String track;
  final String to;
  final double rollout;
  final bool dryRun;

  PlayStorePromoteTask({
    required this.version,
    required this.track,
    required this.to,
    required this.rollout,
    required this.dryRun,
  });

  Future<void> run() async {
    log('${version ?? 'release'} promotion ${dryRun ? 'validation' : ''}');

    final fromTrack = await api.get(track: track);
    Iterable<TrackRelease>? releases = fromTrack.releases;
    if (releases == null) {
      return error('$track track does not have any release');
    }

    TrackRelease? release;
    if (version != null) {
      release = releases.firstWhereOrNull((release) => release.name == version);
      if (release == null) {
        return error('$version does not exist on $track track');
      }
    } else {
      releases = releases.where((release) => release.status == 'completed');
      if (releases.isEmpty) {
        return error('$track track does not have any completed release');
      } else if (releases.length > 1) {
        return error('$track track does have more than one completed release');
      }
      release = releases.first;
    }

    if (rollout == 1) {
      release.status = 'completed';
    } else if (rollout > 0 && rollout < 1) {
      release.status = 'inProgress';
      release.userFraction = rollout;
    } else {
      release.status = 'draft';
    }

    final toTrack = await api.get(track: to);
    if (toTrack.releases?.any((lookup) => lookup.name == release!.name) == true) {
      return warning('${release.name} already on $to track');
    }

    toTrack.releases = [release];

    await api.update(toTrack);
    await api.commit(validateOnly: dryRun);

    success('${release.name} promotion ${dryRun ? 'valid' : 'successful'}');
  }
}
