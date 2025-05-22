using System.Runtime.CompilerServices;

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
  public static void Info(string message, [CallerMemberName] string caller = "", [CallerFilePath] string sourceFilePath = "", [CallerLineNumber] int lineNumber = 0)
    => Log(LogLevel.Info, message, caller, sourceFilePath, lineNumber);
  public static void Error(string message, [CallerMemberName] string caller = "", [CallerFilePath] string sourceFilePath = "", [CallerLineNumber] int lineNumber = 0)
    => Log(LogLevel.Error, message, caller, sourceFilePath, lineNumber);
  public static void Error(string message, Exception exception, [CallerMemberName] string caller = "", [CallerFilePath] string sourceFilePath = "", [CallerLineNumber] int lineNumber = 0)
    => Log(LogLevel.Error, $"{message} - {exception.Message}", caller, sourceFilePath, lineNumber);
  public static void Debug(string message, [CallerMemberName] string caller = "", [CallerFilePath] string sourceFilePath = "", [CallerLineNumber] int lineNumber = 0)
    => Log(LogLevel.Debug, message, caller, sourceFilePath, lineNumber);
  public static void DebugGit(string message, [CallerMemberName] string caller = "", [CallerFilePath] string sourceFilePath = "", [CallerLineNumber] int lineNumber = 0)
    => Log(LogLevel.DebugGit, message, caller, sourceFilePath, lineNumber);

  public static void OpenLogFile() {
    if (!LogToFile) return;
    var logDir = Path.GetDirectoryName(LogFilePath)!;
    if (!Directory.Exists(logDir))
      Directory.CreateDirectory(logDir);
    System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo {
      FileName = LogFilePath, UseShellExecute = true
    });
  }
  #endregion

  #region Implementation -------------------------------------------------------
  private static void Log(LogLevel level, string message, string caller, string source, int line) {
    if (level > LogLevel) return;
    var logMessage = new LogMessage(level, message, caller, Path.GetFileName(source), line);
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

public class LogMessage(LogLevel level, string message, string caller, string source, int line) {
  private LogLevel Level { get; } = level;
  private string Message { get; } = message;
  private DateTime Timestamp { get; } = DateTime.Now;
  private string Caller { get; } = caller;
  private string Source { get; } = source;
  private int Line { get; } = line;

  public override string ToString() {
    if (Level == LogLevel.Error || Level >= LogLevel.Debug) {
      return $"{Timestamp:yyyy-MM-dd HH:mm:ss} [{Level}-{Caller}-{Source}:{Line}]  {Message})";
    }
    return $"{Timestamp:yyyy-MM-dd HH:mm:ss} [{Level}] {Message}";
  }

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
  Error
  , Info
  , Debug
  , DebugGit
}
