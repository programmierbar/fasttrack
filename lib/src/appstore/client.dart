import 'package:appstore_connect/appstore_connect.dart';
import 'package:collection/collection.dart';
import 'package:fasttrack/src/common/command.dart';
import 'package:fasttrack/src/common/metadata.dart';

extension DurationExtension on Duration {
  String toFormattedString() {
    return [
      if (inHours > 0) inHours,
      inMinutes.remainder(60),
      inSeconds.remainder(60).toString().padLeft(2, '0'),
    ].join(':');
  }
}

extension AppStoreVersionExtension on AppStoreVersion {
  Future<bool> updateVersionString(String version) async {
    if (versionString != version) {
      await update(AppStoreVersionAttributes(versionString: version));
      return true;
    }
    return false;
  }

  Future<bool> updateReleaseType({required ReleaseType releaseType, DateTime? earliestReleaseDate}) async {
    if (this.releaseType != releaseType) {
      await update(AppStoreVersionAttributes(
        releaseType: releaseType,
        earliestReleaseDate: earliestReleaseDate,
      ));
      return true;
    }
    return false;
  }

  Future<bool> updatePhasedRelease({required bool phased}) async {
    if (phased && phasedRelease == null) {
      await setPhasedRelease(PhasedReleaseAttributes(
        phasedReleaseState: PhasedReleaseState.inactive,
      ));
      return true;
    }

    if (!phased && phasedRelease != null) {
      await phasedRelease!.delete();
      return true;
    }

    return false;
  }

  Future<bool> updateReleaseNotes(Map<String, String> releaseNotes) async {
    final localizations = await getLocalizations();
    final results = await Future.wait(localizations.map((localization) async {
      final locale = localization.locale;
      final lookup = releaseNotes.keys.firstWhereOrNull((key) => key.startsWith(locale));
      if (lookup == null) {
        throw TaskException('Releases notes for locale $locale missing');
      }

      final whatsNew = releaseNotes[lookup];
      if (localization.whatsNew != whatsNew) {
        await localization.update(VersionLocalizationAttributes(whatsNew: whatsNew));
        return true;
      }

      return false;
    }));

    return results.reduce((value, result) => value || result);
  }

  Future<bool> updateSubmission({required bool rejected}) async {
    if (!rejected && submission == null) {
      await addSubmission();
      return true;
    }

    if (rejected && submission != null) {
      if (!submission!.canReject) {
        throw TaskException('$versionString can not be rejected anymore');
      }
      await submission!.delete();
      return true;
    }

    return false;
  }

  Future<bool> updateReleaseState(PhasedReleaseState state) async {
    if (phasedRelease != null && phasedRelease!.phasedReleaseState != state) {
      await phasedRelease!.update(PhasedReleaseAttributes(phasedReleaseState: state));
      return true;
    }

    return false;
  }
}

class AppStoreApiClient {
  static const _platform = AppStorePlatform.iOS;
  static const _pollInterval = Duration(seconds: 15);

  final AppStoreConnectApi api;
  final ReleaseNotesLoader? loader;

  const AppStoreApiClient(this.api, this.loader);

  Future<AppStoreVersion?> getVersion(String version) {
    return _getVersion(versions: [version]);
  }

  Future<AppStoreVersion?> liveVersion() {
    return _getVersion(states: AppStoreState.liveStates);
  }

  Future<AppStoreVersion?> editVersion() {
    return _getVersion(states: [...AppStoreState.editStates, AppStoreState.pendingDeveloperRelease]);
  }

  Future<AppStoreVersion?> _getVersion({List<String>? versions, List<AppStoreState>? states}) async {
    return (await api.getVersions(versions: versions, states: states, platforms: [_platform])).firstOrNull;
  }

  Future<AppStoreVersion> createVersion(String version) {
    return api.postVersion(attributes: AppStoreVersionAttributes(versionString: version, platform: _platform));
  }

  Future<AppStoreVersion> awaitVersionInState({
    required String version,
    required AppStoreState state,
    Duration poll = _pollInterval,
    void Function(String)? log,
  }) async {
    log?.call('Waiting for version $version to reach state ${state.toString().toLowerCase()}');
    final startTime = DateTime.now();

    while (true) {
      await Future.delayed(poll);
      final duration = DateTime.now().difference(startTime);

      log?.call('Waiting for version $version to reach state ${state.toString().toLowerCase()} '
          'for ${duration.toFormattedString()}');
      final lookup = (await api.getVersions(versions: [version], states: [state])).firstOrNull;
      if (lookup != null) {
        return lookup;
      }
    }
  }

  Future<bool> updateReleaseNotes(AppStoreVersion version) async {
    if (loader == null) {
      return false;
    }

    final releaseNotes = await loader!.load();
    return version.updateReleaseNotes(releaseNotes);
  }

  Future<Build?> getBuild({
    required String version,
    String? buildNumber,
    Duration? poll = _pollInterval,
    void Function(String)? log,
  }) async {
    final build = (await api.getBuilds(version: version, buildNumber: buildNumber)).firstOrNull;
    if (build != null && build.processed || poll == null) {
      return build;
    }

    log?.call('Waiting for build version $version ($buildNumber) to be processed');
    final startTime = DateTime.now();

    while (true) {
      await Future.delayed(poll);
      final duration = DateTime.now().difference(startTime);

      log?.call('Waiting for build $version ($buildNumber) to be processed for ${duration.toFormattedString()}');
      final build = (await api.getBuilds(version: version, buildNumber: buildNumber)).firstOrNull;
      if (build != null && build.processed) {
        return build;
      }
    }
  }
}
