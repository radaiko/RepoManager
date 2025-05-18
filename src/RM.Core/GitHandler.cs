using RM.Base;

namespace RM.Core;

using System.Diagnostics;

public static class GH {
  public static string Run(string command, string workingDirectory) {
    var psi = new ProcessStartInfo {
      FileName = "git", 
      Arguments = command, 
      WorkingDirectory = workingDirectory, 
      RedirectStandardOutput = true, 
      RedirectStandardError = true, 
      UseShellExecute = false, 
      CreateNoWindow = true
    };
    var sw = new Stopwatch();
    if (Logger.LogLevel == LogLevel.Debug) {
      sw.Start();
    }
    using var process = Process.Start(psi);
    if (process == null) {
      Logger.Error($"Failed to start git process with command: {command}");
      throw new InvalidOperationException("Failed to start git process.");
    }
    var output = process.StandardOutput.ReadToEnd();
    var error = process.StandardError.ReadToEnd();
    process.WaitForExit();
    if (Logger.LogLevel == LogLevel.Debug) {
      sw.Stop();
      Logger.Debug($"git {command} -- took {sw.ElapsedMilliseconds} ms");
    }
    if (process.ExitCode == 0) return output.TrimEnd('\r', '\n');
    Logger.Error($"Git command failed with exit code {process.ExitCode}: {error}");
    throw new Exception($"Git command failed: {error}");
  }
}