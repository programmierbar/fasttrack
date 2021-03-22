import 'package:args/command_runner.dart' as args;
import 'package:dart_console/dart_console.dart';

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
    var line = 0;
    //var line = console.cursorPosition!.row - tasks.length;
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
    } on TaskException catch (error) {
      task.error(error.message);
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

  void success(String text) => log(text, color: StatusColor.success);
  void warning(String text) => log(text, color: StatusColor.warning);
  void error(String text) => log(text, color: StatusColor.error);
  void log(String text, {StatusColor color = StatusColor.info}) => _output.write('$appId: $text', color: color);
}

class TaskException implements Exception {
  final String message;
  TaskException(this.message);
}

class ConsoleOutput {
  final Console _console;
  final int _row;

  ConsoleOutput._(this._console, this._row);

  void write(String text, {StatusColor? color}) {
    _console.cursorPosition = Coordinate(_row, 0);
    if (color != null) {
      _console.setForegroundColor(color._color);
    }
    _console.eraseLine();
    _console.write(text);
  }
}

class StatusColor {
  static const info = StatusColor._(ConsoleColor.white);
  static const success = StatusColor._(ConsoleColor.green);
  static const warning = StatusColor._(ConsoleColor.yellow);
  static const error = StatusColor._(ConsoleColor.red);

  final ConsoleColor _color;
  const StatusColor._(this._color);
}
