namespace RM.Base;

public static class Logger {
  #region Properties -----------------------------------------------------------
  /// <summary>Set until which LogLevel should be logged</summary>
  public static LogLevel LogLevel { get; set; }
  public static bool LogToConsole { get; set; }
  public static bool LogToFile { get; set; } = true;

  public static Queue<LogMessage> LogMessages { get; } = [];
  #endregion

  #region Events ---------------------------------------------------------------
  public static event Action? OnLogMessageAdded;
  #endregion

  #region Variables ------------------------------------------------------------
  private static readonly string LogFilePath = Path.Combine(
    Common.GetAppDataPath(),
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
  public static void Error(string message, string? exception) {
    Log(LogLevel.Error, $"{message} - {exception}");
  }
  public static void Error(string message, Exception exception) {
    Log(LogLevel.Error, $"{message} - {exception.Message}");
  }
  public static void Debug(string message) {
    Log(LogLevel.Debug, message);
  }

  public static void DebugGit(string message) {
    Log(LogLevel.DebugGit, message);
  }

  public static void OpenLogFile() {
    if (LogToFile) {
      var logDir = Path.GetDirectoryName(LogFilePath)!;
      if (!Directory.Exists(logDir))
        Directory.CreateDirectory(logDir);
      System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo {
        FileName = LogFilePath,
        UseShellExecute = true
      });
    }
  }
  #endregion

  #region Implementation -------------------------------------------------------
  private static void Log(LogLevel level, string message) {
    if (level > LogLevel) return;
    var logMessage = new LogMessage(level, message);
    LogMessages.Enqueue(logMessage);
    if (LogToFile)
      InternalLogToFile(logMessage);
    if (LogToConsole)
      logMessage.ToConsole();
    OnLogMessageAdded?.Invoke();
  }

  private static void InternalLogToFile(LogMessage message) {
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
  #endregion
}

public class LogMessage(LogLevel level, string message) {
  public LogLevel Level { get; } = level;
  public string Message { get; } = message;
  public DateTime Timestamp { get; } = DateTime.Now;

  public override string ToString() => $"{Timestamp:yyyy-MM-dd HH:mm:ss} [{Level}] {Message}";

  public void ToConsole() {
    Console.ForegroundColor = Level switch {
      LogLevel.Info => ConsoleColor.White,
      LogLevel.Error => ConsoleColor.Red,
      LogLevel.Debug => ConsoleColor.Gray,
      _ => Console.ForegroundColor
    };
    Console.WriteLine(ToString());
    Console.ResetColor();
  }
}

public enum LogLevel {
  Error,
  Info,
  Debug,
  DebugGit
}
