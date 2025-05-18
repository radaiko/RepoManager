using System.Diagnostics;

namespace RM.Playground;

/// <summary>Common methods for the RepoManager</summary>
public static class Common {
  /// <summary>Run a git command and returns StandardOutput</summary>
  public static string RunGitCommand(string args, string workingDirectory)
  {
    var process = new Process
    {
      StartInfo = new ProcessStartInfo
      {
        FileName = "git",
        Arguments = args,
        WorkingDirectory = workingDirectory,
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true
      }
    };
    process.Start();
    string output = process.StandardOutput.ReadToEnd();
    process.WaitForExit();
    return output.Trim();
  }
}