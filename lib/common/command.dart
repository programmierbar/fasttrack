import 'dart:convert';

import 'package:args/command_runner.dart' as args;
import 'package:dart_console/dart_console.dart';
import 'package:googleapis/abusiveexperiencereport/v1.dart';

abstract class Command extends args.Command {
  static const _dryRunFlag = 'dry-run';

  Command() {
    argParser.addFlag(
      _dryRunFlag,
      abbr: 'd',
      help: 'Whether to only validate the promotion',
    );
  }

  bool get dryRun => getParam(_dryRunFlag);

  T? getParam<T>(String name) => argResults?[name] as T?;
  Iterable<T>? getList<T>(String name) => (argResults?[name] as String?)?.split(',').cast<T>();

  Future<List<CommandTask>> setup();

  Future<void> run() async {
    final tasks = await setup();

    final console = Console();
    for (final task in tasks) {
      console.writeLine('${task.appId}: initializing...');
    }
    var line = console.cursorPosition!.row - tasks.length;
    for (final task in tasks) {
      task._output = ConsoleOutput._(console, line++);
    }
    console.hideCursor();

    await Future.wait(tasks.map(_runTask));

    console.showCursor();
    console.cursorPosition = Coordinate(line, 0);
  }

  Future<void> _runTask(CommandTask task) async {
    try {
      await task.run();
    } on DetailedApiRequestError catch (error) {
      task.error(error.toString());
      print(jsonEncode(error.jsonResponse));
      for (final part in error.errors) {
        print(part);
      }
    } catch (error) {
      task.error(error.toString());
    }
  }
}

abstract class CommandTask {
  late final String appId;
  late final ConsoleOutput _output;

  CommandTask();

  Future<void> run();

  void success(String text) => info(text, color: ConsoleColor.green);
  void warning(String text) => info(text, color: ConsoleColor.yellow);
  void error(String text) => info(text, color: ConsoleColor.red);
  void info(String text, {ConsoleColor color = ConsoleColor.white}) {
    _output.write('$appId: $text', color: color);
  }
}

class ConsoleOutput {
  final Console _console;
  final int _row;

  ConsoleOutput._(this._console, this._row);

  void write(String text, {ConsoleColor? color}) {
    _console.cursorPosition = Coordinate(_row, 0);
    if (color != null) {
      _console.setForegroundColor(color);
    }
    _console.eraseLine();
    _console.write(text);
  }
}
