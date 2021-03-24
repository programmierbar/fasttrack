import 'dart:io';

import 'package:yaml/yaml.dart';

class Version {
  final String version;
  final String? build;

  factory Version(String version) {
    final parts = version.split('+');
    return Version._(
      version: parts[0],
      build: parts.length > 1 ? parts[1] : null,
    );
  }
  const Version._({required this.version, this.build});
}

class Context {
  static Future<Context?> setup(String path) async {
    final file = File('$path/pubspec.yaml');
    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content);

    return Context._(yaml);
  }

  final Version version;

  Context._(YamlMap yaml) : version = Version(yaml['version']);
}
