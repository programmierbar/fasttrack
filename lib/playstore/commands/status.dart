import 'package:fasttrack/playstore/commands/command.dart';
import 'package:fasttrack/playstore/config.dart';

class PlayStoreStatusCommand extends PlayStoreCommand {
  final name = 'status';
  final description = 'Get the status of all app versions';

  PlayStoreStatusCommand(PlayStoreConfig config) : super(config) {
    argParser.addMultiOption(
      'package',
      abbr: 'p',
      help: 'Whether to get the status only for a specific package',
      allowed: config.packageNames.keys,
    );
    argParser.addOption(
      'track',
      abbr: 't',
      help: 'The track to get status information for',
      allowed: ['production', 'internal'],
      defaultsTo: 'production',
    );
  }

  Future<void> run() async {
    var ids = config.packageNames.keys;
    if ((argResults?['package'] as List?)?.isNotEmpty == true) {
      ids = argResults?['package'] as List<String>;
    }
    final track = argResults?['track'];

    final client = await getClient();
    final results = Map.fromIterables(
      ids,
      await Future.wait(ids.map((id) => client.getReleases(package: config.packageNames[id]!, track: track))),
    );

    for (final entry in results.entries) {
      final releases = entry.value;
      if (releases != null) {
        for (final release in releases) {
          print([
            '${entry.key}:',
            release.name,
            '(${release.versionCodes?.join(', ')})',
            '->',
            release.status,
            release.userFraction != null ? '${release.userFraction! * 100}%' : null,
          ].where((part) => part != null).join(' '));
        }
      }
    }

    client.close();
  }
}
