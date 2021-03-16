import 'package:args/command_runner.dart' as args;
import 'package:dart_console/dart_console.dart';

abstract class Command extends args.Command {
  T? getParam<T>(String name) => argResults?[name] as T?;
  Iterable<T>? getList<T>(String name) => (argResults?[name] as String?)?.split(',').cast<T>();

  Future<List<CommandTask>> setup();

  Future<void> run() async {
    final tasks = await setup();

    final console = Console();
    for (final _ in tasks) {
      console.writeLine();
    }
    var line = console.cursorPosition!.row - tasks.length;
    for (final task in tasks) {
      task.output = ConsoleOutput._(console, line++);
    }
    console.hideCursor();

    await Future.wait(tasks.map((task) => task.run()));

    console.showCursor();
    console.cursorPosition = Coordinate(line, 0);
  }
}

abstract class CommandTask {
  late final String appId;
  late final ConsoleOutput output;

  CommandTask();

  Future<void> run();
}

class StatusColor {
  static const info = StatusColor._(ConsoleColor.white);
  static const success = StatusColor._(ConsoleColor.green);
  static const warning = StatusColor._(ConsoleColor.yellow);
  static const error = StatusColor._(ConsoleColor.red);

  final ConsoleColor _color;

  const StatusColor._(this._color);
}

class ConsoleOutput {
  final Console _console;
  final int _row;

  ConsoleOutput._(this._console, this._row);

  void write(String text, {StatusColor color = StatusColor.info}) {
    _console.cursorPosition = Coordinate(_row, 0);
    _console.setForegroundColor(color._color);
    _console.write(text);
  }
}
