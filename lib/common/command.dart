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
      task._output = ConsoleOutput._(console, line++);
    }
    console.hideCursor();

    await Future.wait(tasks.map((task) => task.run()));

    console.showCursor();
    console.cursorPosition = Coordinate(line, 0);
  }
}

abstract class CommandTask {
  late final String appId;
  late final ConsoleOutput _output;

  CommandTask();

  Future<void> run();

  void writeSuccess(String text) => write(text, color: ConsoleColor.green);
  void writeWarning(String text) => write(text, color: ConsoleColor.yellow);
  void writeError(String text) => write(text, color: ConsoleColor.red);
  void write(String text, {ConsoleColor color = ConsoleColor.white}) {
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
