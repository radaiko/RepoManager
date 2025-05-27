extension StringExtensions on String {
  /// Split by lines
  List<String> lineSplit() {
    var output = split(
      '\n',
    ).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    return output;
  }

  String getFileName() {
    return split(RegExp(r'[/\\]')).last;
  }
}

extension StopwatchExtensions on Stopwatch {
  /// Returns the elapsed time in a human-readable format
  String get elapsedHumanReadable {
    final duration = elapsed;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours}h ${minutes}m ${seconds}s';
  }
}
