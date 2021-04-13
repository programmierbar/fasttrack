import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/common/config.dart';
import 'package:fasttrack/common/context.dart';
import 'package:fasttrack/playstore/commands/command.dart';

Future<void> main(List<String> args) async {
  final config = await StoreConfig.load('.');
  final context = await Context.setup('.');

  final runner = CommandRunner('fasttrack', 'Forget crappy fastlane, here comes fasttrack!!!');
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
