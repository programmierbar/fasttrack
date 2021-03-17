import 'package:collection/collection.dart';
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
      _trackOption,
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
    info('loading...');

    final track = await api.get(track: this.track);
    final releases = track.releases;

    if (releases == null) {
      error('no releases');
    } else if (version != null) {
      final release = releases.firstWhereOrNull((release) => release.name == version);
      if (release == null) {
        error('$version -> not available');
      } else {
        _writeRelease(release);
      }
    } else {
      _writeRelease(releases.first);
    }

    await api.abort();
  }

  void _writeRelease(TrackRelease release) {
    final text = [
      release.name,
      '(${release.versionCodes?.join(', ')})',
      '->',
      release.status,
      release.userFraction != null ? '(${(release.userFraction! * 100).round()}%)' : null,
    ].where((part) => part != null).join(' ');
    if (release.status == 'inProgress') {
      warning(text);
    } else {
      success(text);
    }
  }
}
