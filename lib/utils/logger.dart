import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'common.dart';
import 'log_message.dart';
import 'log_level.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;

class Logger {
  // Properties
  static LogLevel logLevel = LogLevel.info;
  static bool logToConsole = false;
  static bool logToFile = true;
  static final Queue<LogMessage> logMessages = Queue<LogMessage>();

  // Event handling
  static final List<Function()> _onLogMessageAddedListeners = [];
  static void addOnLogMessageAddedListener(Function() listener) {
    _onLogMessageAddedListeners.add(listener);
  }

  static void removeOnLogMessageAddedListener(Function() listener) {
    _onLogMessageAddedListeners.remove(listener);
  }

  // File path
  static String? _logFilePath;
  static Future<String> get logFilePath async {
    _logFilePath ??= path.join(
      await Common.getAppDataPath(),
      'RepoManager.log',
    );
    return _logFilePath!;
  }

  // Public interface
  static void info(
    String message, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => log(LogLevel.info, message);

  static void error(
    String message, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => log(LogLevel.error, message);

  static void errorWithException(
    String message,
    Exception exception, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => log(LogLevel.error, '$message - ${exception.toString()}');

  static void debug(
    String message, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => log(LogLevel.debug, message);

  static void debugGit(
    String message, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => log(LogLevel.debugGit, message);

  static Future<void> openLogFile() async {
    if (!logToFile) return;

    final logDir = path.dirname(await logFilePath);
    if (!Directory(logDir).existsSync()) {
      await Directory(logDir).create(recursive: true);
    }

    Process.start('open', [await logFilePath]);
  }

  // Implementation
  static void log(LogLevel level, String message) {
    if (level.index > logLevel.index) return;

    final trace = stack_trace.Trace.current();
    final caller = trace.frames[2].member.toString();
    final source = trace.frames[2].uri.toString();
    final line = trace.frames[2].line;

    final logMessage = LogMessage(
      level,
      message,
      caller,
      path.basename(source),
      line ?? -1,
    );
    logMessages.add(logMessage);

    if (logToFile) {
      _logToFile(logMessage);
    }
    if (logToConsole) {
      logMessage.toConsole();
    }

    for (var listener in _onLogMessageAddedListeners) {
      listener();
    }
  }

  static void _logToFile(LogMessage message) async {
    final logDir = path.dirname(await logFilePath);
    if (!Directory(logDir).existsSync()) {
      Directory(logDir).createSync(recursive: true);
    }

    const maxSize = 10 * 1024 * 1024; // 10MB
    final file = File(await logFilePath);
    if (file.existsSync() && file.lengthSync() > maxSize) {
      final backupPath = path.join(logDir, 'RepoManager.log.1');
      if (File(backupPath).existsSync()) {
        File(backupPath).deleteSync();
      }
      file.renameSync(backupPath);
      file.createSync();
    }
    file.writeAsStringSync('$message\n', mode: FileMode.append);
  }
}
