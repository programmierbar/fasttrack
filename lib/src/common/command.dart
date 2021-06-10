import 'package:args/command_runner.dart' as args;
import 'package:dart_console/dart_console.dart';
import 'package:fasttrack/src/common/config.dart';
import 'package:fasttrack/src/common/context.dart';

abstract class CommandGroup extends args.Command {
  final Context? context;

  CommandGroup(this.context);

  void addCommands(Iterable<Command> commands) {
    for (final command in commands) {
      command.context = context;
      addSubcommand(command);
    }
  }
}

abstract class Command extends args.Command {
  static const appOption = 'app';
  static const versionOption = 'version';
  static const checkFlag = 'check';

  final console = Console();
  late final Context? context;

  Command() {
    argParser.addOption(
      versionOption,
      abbr: 'v',
      help: 'The version that should be handled.',
    );
    if (checked) {
      argParser.addFlag(
        checkFlag,
        help: 'Whether a check prompt is shown to acknowledge the command',
        defaultsTo: true,
      );
    }
  }

  Iterable<String> get appIds => getList<String>(appOption)!;

  String? get version {
    final version = getParam(versionOption);
    if (version == null) {
      return context?.version.version;
    } else {
      return version;
    }
  }

  bool get checked => false;
  String get prompt => 'Do you really want to run the command?';

  T? getParam<T>(String name) => argResults?[name] as T?;
  Iterable<T>? getList<T>(String name) => argResults?[name] != null ? argResults![name].cast<T>() : null;

  Future<List<CommandTask>> setup();

  Future<void> run() async {
    if (!_check()) {
      return;
    }

    final tasks = await setup();
    for (final task in tasks) {
      console.writeLine('${task.id}: initializing...');
    }

    //var line = 0;
    var line = console.cursorPosition!.row - tasks.length;
    for (final task in tasks) {
      task._logger = ConsoleLogger._(console, line++);
    }

    console.hideCursor();
    await Future.wait(tasks.map(_runTask));
    console.showCursor();
    console.cursorPosition = Coordinate(line, 0);
  }

  bool _check() {
    if (checked) {
      final check = getParam<bool>(checkFlag);
      if (check == true) {
        console.write('$prompt (y/N) ');
        final key = console.readKey();
        return key.char == 'y' || key.char == 'Y';
      }
    }

    return true;
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
  late final ConsoleLogger _logger;

  CommandTask();

  String get id;
  Future<void> run();

  void success(String text) => log(text, color: StatusColor.success);
  void warning(String text) => log(text, color: StatusColor.warning);
  void error(String text) => log(text, color: StatusColor.error);
  void log(String text, {StatusColor color = StatusColor.info}) =>
      _logger.write(id == DefaultAppId ? text : '$id: $text', color: color);
}

class TaskException implements Exception {
  final String message;
  TaskException(this.message);
}

class ConsoleLogger {
  final Console _console;
  final int _row;

  ConsoleLogger._(this._console, this._row);

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
