#!/usr/bin/env dart

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fasttrack/appstore/commands/command.dart';
import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/common/config.dart';
import 'package:fasttrack/playstore/commands/command.dart';
import 'package:fasttrack/playstore/config.dart';

const config = StoreConfig(
  appStore: AppStoreConfig(
    keyId: '47KUQ5A2CF',
    issuerId: '69a6de6f-9699-47e3-e053-5b8c7c11a4d1',
    keyFile: './credentials/AuthKey_47KUQ5A2CF.pem',
    appIds: {
      'de': '595098366',
      'en': '595558452',
      'fr': '596006531',
      'es': '598945891',
      'it': '598938741',
      'br': '814352052',
      'nl': '601316585',
      'ru': '598949838'
    },
  ),
  playStore: PlayStoreConfig(
    keyFile: './credentials/pics-8f026-f32e0b8abb61.json',
    packageNames: {
      'de': 'de.lotum.whatsinthefoto.de',
      'en': 'de.lotum.whatsinthefoto.us',
      'fr': 'de.lotum.whatsinthefoto.fr',
      'es': 'de.lotum.whatsinthefoto.es',
      'it': 'de.lotum.whatsinthefoto.it',
      'br': 'de.lotum.whatsinthefoto.brazil',
      'nl': 'de.lotum.whatsinthefoto.nl',
      'ru': 'de.lotum.whatsinthefoto.ru'
    },
  ),
);

Future<void> main(List<String> args) async {
  final runner = CommandRunner('fasttrack', 'Forget crappy fastlane, here comes fasttrack!!!');
  if (config.appStore != null) {
    runner.addCommand(AppStoreCommandGroup(config.appStore!));
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
