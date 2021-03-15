#!/usr/bin/env dart

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fasttrack/appstore/commands/command.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner('fasttrack', 'Forget crappy fastlane, here comes fasttrack!!!')
    ..addCommand(AppStoreCommand());

  try {
    await runner.run(args);
    exit(0);
  } catch (error) {
    if (error is! UsageException) rethrow;
    print(error);
    exit(64);
  }
}
