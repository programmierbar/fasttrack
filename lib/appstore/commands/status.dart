import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/common/command.dart';

class AppStoreStatusCommand extends AppStoreCommand {
  final name = 'status';
  final description = 'Get the status of all app versions';

  AppStoreCommandTask setupTask() {
    return AppStoreStatusTask(version);
  }
}

class AppStoreStatusTask extends AppStoreCommandTask {
  final String? version;

  AppStoreStatusTask(this.version);

  Future<void> run() async {
    log('loading...');

    final versions = await api.getVersions(
      versions: version != null ? [version!] : null,
      states: version == null ? AppStoreState.liveStates : null,
    );

    if (versions.isEmpty) {
      return error(version == null ? 'no version available' : '$version not available');
    }

    _print(versions.first);
  }

  void _print(AppStoreVersion version) {
    var color = StatusColor.info;
    final parts = [version.versionString];
    if (version.build != null) {
      parts.add('(${version.build!.version})');
    }
    if (version.appStoreState != AppStoreState.readyForSale) {
      parts.add(version.appStoreState.toString().toLowerCase());
      color = StatusColor.warning;
    } else {
      final release = version.phasedRelease;
      if (release == null) {
        parts.add('completed');
        color = StatusColor.success;
      } else {
        if (release.phasedReleaseState == PhasedReleaseState.complete) {
          parts.add('completed');
          color = StatusColor.success;
        } else if (release.phasedReleaseState == PhasedReleaseState.active) {
          parts.add('inProgress (${(release.userFraction * 100).round()}%)');
          color = StatusColor.warning;
        } else if (release.phasedReleaseState == PhasedReleaseState.paused) {
          parts.add('halted (${release.totalPauseDuration.inDays} days)');
          color = StatusColor.warning;
        } else {
          parts.add(release.phasedReleaseState.toString());
        }
      }
    }
    log(parts.join(' '), color: color);
  }
}
