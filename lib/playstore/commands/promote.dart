import 'package:collection/collection.dart';
import 'package:fasttrack/playstore/commands/command.dart';
import 'package:fasttrack/playstore/config.dart';
import 'package:googleapis/androidpublisher/v3.dart';

class PlayStorePromoteCommand extends PlayStoreCommand {
  static const _versionOption = 'version';
  static const _fromOption = 'from';
  static const _toOption = 'to';
  static const _rolloutOption = 'rollout';
  static const _dryRunFlag = 'dry-run';

  final name = 'promote';
  final description = 'Promote a release version from on track to another';

  PlayStorePromoteCommand(PlayStoreConfig config) : super(config) {
    argParser.addOption(
      _versionOption,
      abbr: 'v',
      help: 'The version to promote to the other track',
    );
    argParser.addOption(
      _fromOption,
      abbr: 'f',
      help: 'The track to promote the version from',
      allowed: ['beta', 'alpha', 'internal'],
      defaultsTo: 'internal',
    );
    argParser.addOption(
      _toOption,
      abbr: 't',
      help: 'The track to promote the version to',
      allowed: ['production', 'beta', 'alpha'],
      defaultsTo: 'production',
    );
    argParser.addFlag(
      _dryRunFlag,
      abbr: 'd',
      help: 'Whether to only validate the promotion',
    );
    argParser.addOption(_rolloutOption, abbr: 'r', help: 'The fraction at which to rollout the version to the users');
  }

  double? _rolloutParam() {
    var rollout = getParam(_rolloutOption);
    if (rollout is String && rollout.contains('%')) {
      rollout = double.tryParse(rollout.replaceAll('%', ''));
      rollout /= 100;
    }
    return rollout;
  }

  PlayStoreCommandTask setupTask() {
    return PlayStorePromoteTask(
        version: getParam(_versionOption),
        from: getParam(_fromOption),
        to: getParam(_toOption),
        rollout: _rolloutParam(),
        dryRun: getParam(_dryRunFlag));
  }
}

class PlayStorePromoteTask extends PlayStoreCommandTask {
  final String? version;
  final String from;
  final String to;
  final double? rollout;
  final bool dryRun;

  PlayStorePromoteTask({
    required this.version,
    required this.from,
    required this.to,
    required this.rollout,
    required this.dryRun,
  });

  Future<void> run() async {
    write('$version promotion ${dryRun ? 'validating' : 'executing'} from $from to $to');

    final fromTrack = await api.get(track: from);
    Iterable<TrackRelease>? releases = fromTrack.releases;
    if (releases == null) {
      throw Exception('Track $from does not have any release');
    }

    TrackRelease? release;
    if (version != null) {
      release = releases.firstWhereOrNull((release) => release.name == version);
      if (release == null) {
        throw Exception('Track $from does not have a release with version $version');
      }
    } else {
      releases = releases.where((release) => release.status == 'completed');
      if (releases.isEmpty) {
        throw Exception('Track $from does not have any completed release');
      } else if (releases.length > 1) {
        throw Exception('Track $from does have more than one completed release');
      }
      release = releases.first;
    }

    if (rollout == null || rollout == 0) {
      release.status = 'draft';
    } else if (rollout == 1) {
      release.status = 'completed';
    } else {
      release.status = 'inProgress';
      release.userFraction = rollout;
    }

    final toTrack = await api.get(track: to);
    if (toTrack.releases != null && toTrack.releases!.any((lookup) => lookup.name == release!.name)) {
      throw Exception('Track $to already has a version ${release.name}');
    }

    toTrack.releases = [release];
    await api.update(toTrack);

    if (dryRun) {
      await api.validate();
      writeSuccess('${release.name} promotion from $from to $to is valid');
    } else {
      await api.commit();
      writeSuccess('${release.name} promotion from $from to $to was successful');
    }
  }
}
