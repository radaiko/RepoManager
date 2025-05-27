import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'common.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;

class Logger {
  // ---------------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------------
  static LogLevel logLevel = LogLevel.info;
  static bool logToConsole = false;
  static bool logToFile = true;
  static final Queue<LogMessage> logMessages = Queue<LogMessage>();

  static String? _logFilePath;
  static Future<String> get logFilePath async {
    _logFilePath ??= path.join(
      await Common.getAppDataPath(),
      'RepoManager.log',
    );
    return _logFilePath!;
  }

  // ---------------------------------------------------------------------------
  // Event handling
  // ---------------------------------------------------------------------------
  static final List<Function()> _onLogMessageAddedListeners = [];
  static void addOnLogMessageAddedListener(Function() listener) {
    _onLogMessageAddedListeners.add(listener);
  }

  static void removeOnLogMessageAddedListener(Function() listener) {
    _onLogMessageAddedListeners.remove(listener);
  }

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------
  static void info(
    String message, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => _log(LogLevel.info, message);

  static void error(
    String message, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => _log(LogLevel.error, message);

  static void errorWithException(
    String message,
    Exception exception, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => _log(LogLevel.error, '$message - ${exception.toString()}');

  static void debug(
    String message, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => _log(LogLevel.debug, message);

  static void debugGit(
    String message, [
    String caller = '',
    String sourceFilePath = '',
    int lineNumber = 0,
  ]) => _log(LogLevel.debugGit, message);

  static Future<void> openLogFile() async {
    if (!logToFile) return;

    final logDir = path.dirname(await logFilePath);
    if (!Directory(logDir).existsSync()) {
      await Directory(logDir).create(recursive: true);
    }

    Process.start('open', [await logFilePath]);
  }

  // ---------------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------------
  static void _log(LogLevel level, String message) {
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

class LogMessage {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String caller;
  final String source;
  final int line;

  LogMessage(this.level, this.message, this.caller, this.source, this.line)
    : timestamp = DateTime.now();

  @override
  String toString() {
    final timeStr =
        '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    final levelName = level.name.toUpperCase();
    if (level == LogLevel.error || level.index >= LogLevel.debug.index) {
      return '$timeStr [$levelName] [$source:$line] $message';
    }
    return '$timeStr [$levelName] $message';
  }

  void toConsole() {
    // Note: ANSI color codes for terminal output
    final resetCode = '\x1B[0m';
    final colorCode = switch (level) {
      LogLevel.info => '\x1B[37m', // White
      LogLevel.error => '\x1B[31m', // Red
      LogLevel.debug => '\x1B[90m', // Gray
      _ => '',
    };

    stdout.writeln('$colorCode$this$resetCode');
  }
}

enum LogLevel { error, info, debug, debugGit }
