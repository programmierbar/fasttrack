import 'package:collection/collection.dart';
import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/appstore/connect_api/model/version.dart';
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/common/metadata.dart';

class AppStoreVersionManager {
  static const _platform = AppStorePlatform.iOS;

  final AppStoreConnectApi api;
  final ReleaseNotesLoader? loader;

  const AppStoreVersionManager(this.api, this.loader);

  Future<AppStoreVersion?> getVersion(String version) async {
    return (await api.getVersions(versions: [version])).firstOrNull;
  }

  Future<AppStoreVersion?> liveVersion() async {
    return (await api.getVersions(states: AppStoreState.liveStates)).firstOrNull;
  }

  Future<AppStoreVersion> editVersion(String version) async {
    final storeVersions = await api.getVersions(
      states: AppStoreState.editStates,
      platforms: [_platform],
    );

    if (storeVersions.isEmpty) {
      return await api.postVersion(
        attributes: AppStoreVersionAttributes(
          versionString: version,
          platform: _platform,
        ),
      );
    }

    final storeVersion = storeVersions.first;
    if (storeVersion.versionString != version) {
      await storeVersion.update(AppStoreVersionAttributes(versionString: version));
    }

    return storeVersion;
  }

  Future<bool> updateReleaseType(AppStoreVersion version, ReleaseType releaseType) async {
    if (version.releaseType != releaseType) {
      await version.update(AppStoreVersionAttributes(releaseType: releaseType));
      return true;
    }
    return false;
  }

  Future<bool> updatePhasedRelease(AppStoreVersion version, {required bool phased}) async {
    final phasedRelease = version.phasedRelease;
    if (phased && phasedRelease == null) {
      await version.setPhasedRelease(AppStoreVersionPhasedReleaseAttributes(
        phasedReleaseState: PhasedReleaseState.inactive,
      ));
      return true;
    } else if (!phased && phasedRelease != null) {
      await phasedRelease.delete();
      return true;
    }
    return false;
  }

  Future<bool> updateReleaseNotes(AppStoreVersion version) async {
    if (loader == null) {
      return false;
    }

    final releaseNotes = await loader!.load();
    final localizations = await version.getLocalizations();

    final results = await Future.wait(localizations.map((localization) async {
      final locale = localization.locale;
      final lookup = releaseNotes.keys.firstWhereOrNull((key) => key.startsWith(locale));
      if (lookup == null) {
        throw TaskException('Releases notes for locale $locale is missing');
      }

      final whatsNew = releaseNotes[lookup];
      if (localization.whatsNew != whatsNew) {
        await localization.update(AppStoreVersionLocalizationAttributes(whatsNew: whatsNew));
        return true;
      }

      return false;
    }));

    return results.reduce((value, result) => value || result);
  }

  Future<bool> updateSubmission(AppStoreVersion version, {required bool rejected}) async {
    final submission = version.submission;
    if (!rejected && submission == null) {
      await version.addSubmission();
      return true;
    } else if (rejected && submission != null) {
      if (!submission.canReject) {
        throw TaskException('${version.versionString} can not be rejected anymore');
      }
      await submission.delete();
      return true;
    }
    return false;
  }

  Future<Build?> getBuild(
    String version, {
    String? buildNumber,
    Duration? poll,
    void Function(String)? log,
  }) async {
    final build = (await api.getBuilds(version: version, buildNumber: buildNumber)).firstOrNull;
    if (build != null && build.processed || poll == null) {
      return build;
    }

    log?.call('Waiting for build version $version ($build} to be processed');
    final startTime = DateTime.now();

    while (true) {
      await Future.delayed(poll);
      final duration = DateTime.now().difference(startTime);

      log?.call('Waiting for build $version ($buildNumber) to be processed for $duration');
      final build = (await api.getBuilds(version: version, buildNumber: buildNumber)).firstOrNull;
      if (build != null && build.processed) {
        return build;
      }
    }
  }
}
