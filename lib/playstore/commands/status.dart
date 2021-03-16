import 'package:collection/collection.dart';
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/playstore/commands/command.dart';
import 'package:fasttrack/playstore/config.dart';
import 'package:googleapis/androidpublisher/v3.dart';

class PlayStoreStatusCommand extends PlayStoreCommand {
  static const _versionOption = 'version';
  static const _trackOption = 'track';

  final name = 'status';
  final description = 'Get the status of all app versions';

  PlayStoreStatusCommand(PlayStoreConfig config) : super(config) {
    argParser.addOption(
      _versionOption,
      abbr: 'v',
      help: 'The version to promote to the other track',
    );
    argParser.addOption(
      'track',
      abbr: 't',
      help: 'The track to get status information for',
      allowed: ['production', 'beta', 'alpha', 'internal'],
      defaultsTo: 'production',
    );
  }

  PlayStoreCommandTask setupTask() {
    return PlayStoreStatusTask(
      version: getParam(_versionOption),
      track: getParam(_trackOption),
    );
  }
}

class PlayStoreStatusTask extends PlayStoreCommandTask {
  final String? version;
  final String track;

  PlayStoreStatusTask({required this.version, required this.track});

  Future<void> run() async {
    output.write('$appId:  loading...');

    final track = await resource.get(track: this.track);
    final releases = track.releases;

    if (releases == null) {
      output.write('$appId -> no releases', color: StatusColor.error);
    } else if (version != null) {
      final release = releases.firstWhereOrNull((release) => release.name == version);
      if (release == null) {
        output.write('$appId: $version -> not available', color: StatusColor.error);
      } else {
        _writeRelease(release);
      }
    } else {
      _writeRelease(releases.first);
    }
  }

  void _writeRelease(TrackRelease release) {
    final parts = [
      '$appId:',
      release.name,
      '(${release.versionCodes?.join(', ')})',
      '->',
      release.status,
      release.userFraction != null ? '(${(release.userFraction! * 100).round()}%)' : null,
    ];
    output.write(
      parts.where((part) => part != null).join(' '),
      color: release.status == 'inProgress' ? StatusColor.warning : StatusColor.success,
    );
  }
}
