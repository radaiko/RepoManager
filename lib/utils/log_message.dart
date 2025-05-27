import 'dart:io';
import 'log_level.dart';

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
