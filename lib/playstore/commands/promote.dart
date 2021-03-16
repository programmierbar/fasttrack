import 'dart:math';

import 'package:fasttrack/playstore/commands/command.dart';
import 'package:fasttrack/playstore/config.dart';

class PlayStorePromoteCommand extends PlayStoreCommand {
  static const _versionOption = 'version';
  static const _fromOption = 'from';
  static const _toOption = 'to';

  final name = 'promote';
  final description = 'Promote a release version from on track to another';

  PlayStorePromoteCommand(PlayStoreConfig config) : super(config) {
    argParser.addOption(
      _versionOption,
      abbr: 'v',
      help: 'The version to promote to the other track',
    );
    argParser.addOption(
      _fromOption,
      abbr: 'f',
      help: 'The track to promote the version from',
      allowed: ['beta', 'alpha', 'internal'],
      defaultsTo: 'internal',
    );
    argParser.addOption(
      _toOption,
      abbr: 't',
      help: 'The track to promote the version to',
      allowed: ['production', 'beta', 'alpha'],
      defaultsTo: 'production',
    );
  }

  PlayStoreCommandTask setupTask() {
    return PlayStorePromoteTask(
      version: getParam(_versionOption),
      from: getParam(_fromOption),
      to: getParam(_toOption),
    );
  }
}

class PlayStorePromoteTask extends PlayStoreCommandTask {
  PlayStorePromoteTask({required String? version, required String from, required String to});

  Future<void> run() async {
    final random = Random();
    for (var i = 0; i <= 50; i++) {
      final progress = (i / 50 * 40).ceil();
      final bar = '[${'#' * progress}${' ' * (40 - progress)}]';
      output.write(bar);
      await Future.delayed(Duration(milliseconds: random.nextInt(100)));
    }
  }
}
