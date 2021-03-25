import 'package:collection/collection.dart';
import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/common/metadata.dart';

class AppStorePrepareCommand extends AppStoreCommand {
  final name = 'prepare';
  final description = '''Prepare new app store version.
  
This will either create a new version, if no editable version is available,
or update the current editable version with the new version string''';

  final ReleaseNotesLoader loader;

  AppStorePrepareCommand(AppStoreConfig config, this.loader) : super(config);

  AppStoreCommandTask setupTask() {
    return AppStorePrepareTask(
      loader: loader,
      version: version,
    );
  }
}

class AppStorePrepareTask extends AppStoreCommandTask {
  final ReleaseNotesLoader loader;
  final String? version;

  AppStorePrepareTask({
    required this.loader,
    required this.version,
  });

  Future<void> run() async {
    if (this.version == null) {
      throw TaskException('version param is missing');
    }

    log('${this.version} preparation');
    final version = await _ensureVersion();
    await _updateReleaseNotes(version);
    success('${this.version} preparation completed');
  }

  Future<AppStoreVersion> _ensureVersion() async {
    final versions = await api.getVersions(states: AppStoreState.editStates, platforms: [AppStorePlatform.iOS]);
    if (versions.isEmpty) {
      return await api.postVersion(
        attributes: AppStoreVersionAttributes(
          versionString: this.version,
          platform: AppStorePlatform.iOS,
        ),
      );
    }

    final version = versions.first;
    if (version.versionString != this.version) {
      await version.update(AppStoreVersionAttributes(versionString: this.version));
    }

    return version;
  }

  Future<void> _updateReleaseNotes(AppStoreVersion version) async {
    final releaseNotes = await loader.load();
    final localizations = await version.getLocalizations();

    await Future.wait(localizations.map((localization) {
      final locale = localization.locale;
      final lookup = releaseNotes.keys.firstWhereOrNull((key) => key.startsWith(locale));
      if (lookup == null) {
        throw TaskException('Releases notes for locale $locale is missing');
      }

      final whatsNew = releaseNotes[lookup];
      if (localization.whatsNew != whatsNew) {
        return localization.update(AppStoreVersionLocalizationAttributes(whatsNew: whatsNew));
      }

      return Future.value();
    }));
  }
}
