import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/common/command.dart';
import 'package:fasttrack/common/metadata.dart';

class AppStoreCreateCommand extends AppStoreCommand {
  final name = 'create';
  final description = 'Create and manage new app store version';

  final ReleaseNotesLoader loader;

  AppStoreCreateCommand(this.loader);

  AppStoreCommandTask setupTask() {
    return AppStoreCreateTask(loader: loader, version: version);
  }
}

class AppStoreCreateTask extends AppStoreCommandTask {
  final ReleaseNotesLoader loader;
  final String? version;

  AppStoreCreateTask({
    required this.loader,
    required this.version,
  });

  Future<void> run() async {
    final version = await _ensureVersion();
    await _updateReleaseNotes(version);
  }

  Future<AppStoreVersion> _ensureVersion() async {
    final versions = await api.getVersions(states: AppStoreState.editStates, platforms: [AppStorePlatform.iOS]);
    if (versions.isEmpty) {
      if (this.version == null) {
        throw TaskException('version param is missing');
      }

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
      final whatsNew = releaseNotes[locale];
      if (whatsNew == null) {
        throw TaskException('Releases notes for locale $locale is missing');
      }
      return localization.update(AppStoreVersionLocalizationAttributes(whatsNew: whatsNew));
    }));
  }
}
