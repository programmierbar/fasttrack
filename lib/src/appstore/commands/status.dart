import 'package:appstore_connect/appstore_connect.dart';
import 'package:fasttrack/src/appstore/commands/command.dart';
import 'package:fasttrack/src/appstore/config.dart';
import 'package:fasttrack/src/common/command.dart';

class AppStoreStatusCommand extends AppStoreCommand {
  final name = 'status';
  final description = '''
Get the status of all versions in the App Store.

If no explicit version is specified, the command takes the version string found in the pubspec.yaml
and reads the status of that version from the App Store. To get the status of the versions that are 
currently live, provide "--version live" option to the command.''';

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
        ? await client.liveVersion()
        : this.version == 'edit'
            ? await client.editVersion()
            : await client.getVersion(this.version!);

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
    if (version.appVersionState != AppVersionState.readyForDistribution) {
      parts.add(version.appVersionState.toString().toLowerCase());
      if (version.appVersionState == AppVersionState.metadataRejected ||
          version.appVersionState == AppVersionState.invalidBinary ||
          version.appVersionState == AppVersionState.rejected) {
        color = StatusColor.error;
      } else if (version.appVersionState == AppVersionState.pendingDeveloperRelease ||
          version.appVersionState == AppVersionState.pendingAppleRelease) {
        color = StatusColor.success;
      } else if (version.appVersionState == AppVersionState.waitingForReview ||
          version.appVersionState == AppVersionState.inReview) {
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
