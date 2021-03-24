import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/common/config.dart';
import 'package:fasttrack/playstore/commands/command.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner('fasttrack', 'Forget crappy fastlane, here comes fasttrack!!!');

  final config = await StoreConfig.fromFile('./fasttrack/config.yml');
  if (config.appStore != null) {
    runner.addCommand(AppStoreCommandGroup(config));
  }
  if (config.playStore != null) {
    runner.addCommand(PlayStoreCommandGroup(config.playStore!));
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
