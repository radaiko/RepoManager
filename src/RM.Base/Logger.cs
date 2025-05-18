namespace RM.Base;

public static class Logger {
  #region Properties -----------------------------------------------------------
  /// <summary>Set until which LogLevel should be logged</summary>
  public static LogLevel LogLevel { get; set; }
  public static bool LogToConsole { get; set; } = false;
  public static bool LogToFile { get; set; } = true;
  #endregion
  
  #region Variables ------------------------------------------------------------
  private static readonly string LogFilePath = Path.Combine(
    Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
    "RepoManager",
    "RepoManager.log"
  );
  #endregion
  
  #region Interface ------------------------------------------------------------
  public static void Info(string message) {
    Log(LogLevel.Info, message);
  }
  public static void Error(string message) {
    Log(LogLevel.Error, message);
  }
  public static void Debug(string message) {
    Log(LogLevel.Debug, message);
  }
  #endregion
  
  #region Implementation -------------------------------------------------------
  private static void Log(LogLevel level, string message) {
    var logMessage = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} [{level}] {message}";
    if (level > LogLevel) return;
    if (LogToFile)
      InternalLogToFile(logMessage);
    if (LogToConsole)
      InternalLogToConsole(level, logMessage);
  }

  private static void InternalLogToFile(string message) {
    var logDir = Path.GetDirectoryName(LogFilePath)!;
    if (!Directory.Exists(logDir))
      Directory.CreateDirectory(logDir);

    const long maxSize = 10 * 1024 * 1024; // 10MB
    if (File.Exists(LogFilePath) && new FileInfo(LogFilePath).Length > maxSize) {
      var backupPath = Path.Combine(logDir, "RepoManager.log.1");
      if (File.Exists(backupPath))
        File.Delete(backupPath);
      File.Move(LogFilePath, backupPath);
      File.Create(LogFilePath).Dispose();
    }
    File.AppendAllText(LogFilePath, message + Environment.NewLine);
  }
  private static void InternalLogToConsole(LogLevel level, string message) {
    Console.ForegroundColor = level switch {
      LogLevel.Info => ConsoleColor.White
      , LogLevel.Error => ConsoleColor.Red
      , LogLevel.Debug => ConsoleColor.Gray
      , _ => Console.ForegroundColor
    };
    Console.WriteLine(message);
    Console.ResetColor();
  }
  #endregion
}

public enum LogLevel {
  Error,
  Info,
  Debug
}