using System.Diagnostics;
using RM.Base;

namespace RM.Core;

// ReSharper disable once InconsistentNaming
public class GHBackup {
  private static GHBackup? _instance;
  private readonly System.Diagnostics.Process _gitProcess;
  private readonly StreamWriter _input;
  private readonly StreamReader _output;

  private GHBackup() {
    _gitProcess = new System.Diagnostics.Process {
      StartInfo = new System.Diagnostics.ProcessStartInfo {
        FileName = "bash",
        Arguments = "-c \"while true; do read cmd; eval \\\"git $cmd\\\"; echo __END__; done\"",
        RedirectStandardInput = true,
        RedirectStandardOutput = true,
        UseShellExecute = false,
        CreateNoWindow = true
      }
    };
    _gitProcess.Start();
    _input = _gitProcess.StandardInput;
    _output = _gitProcess.StandardOutput;
  }

  private static GHBackup Instance => _instance ??= new GHBackup();

  private string RunGitCommand(string command, string workingDirectory) {
    lock (_gitProcess) {
      var sw = new Stopwatch();
      if (Logger.LogLevel == LogLevel.Debug) {
        sw.Start();
      }
      _input.WriteLine($"-C \"{workingDirectory}\" {command}");
      _input.Flush();
      var result = new System.Text.StringBuilder();
      string? line;
      while ((line = _output.ReadLine()) != null) {
        if (line == "__END__") break;
        result.AppendLine(line);
      }
      if (sw.IsRunning) {
        sw.Stop();
        Logger.Debug($"git -C \"{workingDirectory}\" {command} -- took {sw.ElapsedMilliseconds} ms");
      }
      return result.ToString().TrimEnd();
    }
  }
  
  public static string RunCommand (string args, string workingDirectory) => Instance.RunGitCommand(args, workingDirectory);
}