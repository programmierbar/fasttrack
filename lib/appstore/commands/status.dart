import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/common/command.dart';

class AppStoreStatusCommand extends AppStoreCommand {
  final name = 'status';
  final description = '''
Get the status of all versions in the appstore

If no explicit version is specified, the command takes the version string found in the pubspec yaml
and reads the status of that version from the appstore. To get the status of the versions that are 
currently live, provide --version live option to the command.''';

  AppStoreStatusCommand(AppStoreConfig config) : super(config);

  AppStoreCommandTask setupTask() {
    return AppStoreStatusTask(version);
  }
}

class AppStoreStatusTask extends AppStoreCommandTask {
  final String? version;

  AppStoreStatusTask(this.version);

  Future<void> run() async {
    log('status loading');
    final version = this.version == 'live'
        ? await manager.liveVersion()
        : this.version == 'edit'
            ? await manager.editVersion()
            : await manager.getVersion(this.version!);

    if (version == null) {
      return error('no ${this.version} version available');
    }

    _print(version);
  }

  void _print(AppStoreVersion version) {
    var color = StatusColor.info;
    final parts = [version.versionString];
    if (version.build != null) {
      parts.add('(${version.build!.version})');
    }
    if (version.appStoreState != AppStoreState.readyForSale) {
      parts.add(version.appStoreState.toString().toLowerCase());
      if (version.appStoreState == AppStoreState.metadataRejected ||
          version.appStoreState == AppStoreState.invalidBinary ||
          version.appStoreState == AppStoreState.rejected) {
        color = StatusColor.error;
      } else if (version.appStoreState == AppStoreState.pendingDeveloperRelease ||
          version.appStoreState == AppStoreState.pendingAppleRelease) {
        color = StatusColor.success;
      } else if (version.appStoreState == AppStoreState.waitingForReview ||
          version.appStoreState == AppStoreState.inReview) {
        color = StatusColor.warning;
      }
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
          parts.add('in_progress (${(release.userFraction * 100).round()}%)');
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
