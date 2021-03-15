import 'package:args/command_runner.dart';
import 'package:fasttrack/common/language.dart';
import 'package:fasttrack/common/platform.dart';
import 'package:fasttrack/playstore/store_controller.dart';

class StatusCommand extends Command {
  final name = 'status';
  final description = 'Get the status of all app versions';

  StatusCommand() {
    argParser.addOption(
      'platform',
      abbr: 'p',
      help: 'Whether to get the status only for a specific platform',
      allowed: Platform.values.map((platform) => platform.toString()),
    );
    argParser.addMultiOption('language',
        abbr: 'l',
        help: 'Whether to get the status only for a specific language',
        allowed: Language.values.map((language) => language.toString()));
    argParser.addOption('track',
        abbr: 't',
        help: 'The track to get status information for',
        allowed: ['production', 'internal'],
        defaultsTo: 'production');
  }

  Future<void> run() async {
    final languages = argResults?['language'] as List<String>?;
    final controller = StoreController();
    await controller.getReleases(
      languages: languages != null && languages.isNotEmpty ? languages.map((code) => Language(code)).toList() : null,
      track: argResults?['track'],
    );
  }
}
