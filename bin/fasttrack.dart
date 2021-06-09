import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fasttrack/src/appstore/commands/command.dart';
import 'package:fasttrack/src/common/config.dart';
import 'package:fasttrack/src/common/context.dart';
import 'package:fasttrack/src/playstore/commands/command.dart';

Future<void> main(List<String> args) async {
  final config = await StoreConfig.load('.');
  final context = await Context.setup('.');

  final runner = CommandRunner('fasttrack', 'Control the release process for your Flutter apps');
  if (config.appStore != null) {
    runner.addCommand(AppStoreCommandGroup(config.appStore!, config.metadata, context));
  }
  if (config.playStore != null) {
    runner.addCommand(PlayStoreCommandGroup(config.playStore!, context));
  }

  try {
    await runner.run(args);
    exit(0);
  } catch (error) {
    if (error is! UsageException) rethrow;
    print(error);
    exit(64);
  }
}
