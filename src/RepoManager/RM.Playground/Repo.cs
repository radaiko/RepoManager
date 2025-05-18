using System.Diagnostics;

namespace RM.Playground;

/// <summary>Represents a git repository</summary>
public class Repo {
  /// <summary>Path to the repository</summary>
  public string Path { get; private set; }
  /// <summary>Nickname of the repository</summary>
  public string Name { get; private set; }
  /// <summary>Current branch of the repository</summary>
  public string CurrentBranch { get; private set; } = "";
  /// <summary>List of branches in the repository</summary>
  public List<Branch> Branches { get; private set; } = new List<Branch>();

  /// <summary>Constructor for the Repo class and check all branches</summary>
  public Repo(string path) {
    Path = path;
    Name = System.IO.Path.GetFileName(Path);
    CheckBranches();
  }
  
  /// <summary>Checks what branches are available and status of it</summary>
  public void CheckBranches() {
    CurrentBranch = GetCurrentBranch();
    var branches = GetAllBranches();
    foreach (var branch in branches) {
      Branches.Add(new Branch (this, branch));
    }
  }

  /// <summary>Check the actual branch</summary>
  public void CheckBranch(string branchName) {
    var branch = Branches.FirstOrDefault(b => b.Name == branchName);
    throw new NotImplementedException("This method is not implemented yet");
  }
  
  #region Git Commands ---------------------------------------------------------
  private string GetCurrentBranch() => Common.RunGitCommand("rev-parse --abbrev-ref HEAD", Path);
  private string GetStatus() => Common.RunGitCommand("status --short", Path);
  private string[] GetAllBranches() => Common.RunGitCommand("branch --list --format='%(refname:short)'", Path)
    .Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries)
    .Select(b => b.Trim('\'', '*', ' '))
    .ToArray();
  #endregion
}