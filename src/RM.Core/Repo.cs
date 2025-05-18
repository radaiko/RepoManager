using System.Diagnostics;
using RM.Base;

namespace RM.Core;

public class Repo {
  #region Properties -----------------------------------------------------------
  public string Path { get; }
  public string Name { get; private set; }
  public bool IsAnalyzed => LastAnalyzeTime > 0;
  public string CurrentBranch { get; private set; }
  public List<Branch> Branches { get; } = new();
  public long LastAnalyzeTime => _lastAnalyzeTime;
  public string MainBranchName { get; private set; }
  public bool IsMainUpToDate {
    get {
      var branch = Branches.FirstOrDefault(b => b.Name.ToLower() == MainBranchName);
      if (branch == null) return false;
      return !branch.IsRemoteAhead || !branch.IsLocalAhead;
    }
  }
  #endregion

  #region Variables ------------------------------------------------------------
  private long _lastAnalyzeTime = 0;
  #endregion

  #region Constructor ----------------------------------------------------------
  public Repo(string path) {
    if (path.EndsWith("/") || path.EndsWith("\\")) path = path.Substring(0, path.Length - 1);
    Path = path;
    Name = System.IO.Path.GetFileName(Path);
    var sw = new Stopwatch();
    sw.Start();
    FetchAll();
    CurrentBranch = GetCurrentBranch();
    var branches = GetAllBranches();
    foreach (var branch in branches) {
      Branches.Add(new Branch(this, branch));
    }
    // check if main branch exists
    if (Branches.Any(b => b.Name.ToLower() == "main")) 
      MainBranchName = "main"; 
    else 
      MainBranchName = "master";
    sw.Stop();
    _lastAnalyzeTime = sw.ElapsedMilliseconds;
    Logger.Debug($"Repo {Name} created and pre analyzed in {_lastAnalyzeTime} ms");
  }
  #endregion

  #region Interface ------------------------------------------------------------
  public void Analyze() {
    var sw = new Stopwatch(); sw.Start();
    Parallel.ForEach(Branches, branch => {
      branch.Analyze();
    });
    sw.Stop();
    _lastAnalyzeTime = sw.ElapsedMilliseconds;
  }

  public void CheckBranch(string branchName) {
    Logger.Debug($"Checking branch {branchName} in Repo {Name}");
    var branch = Branches.FirstOrDefault(b => b.Name == branchName);
    branch?.Analyze();
  }

  public override string ToString() {
    var sb = new System.Text.StringBuilder();
    sb.AppendLine($"Repository: {Name}");
    sb.AppendLine($"Path: {Path}");
    sb.AppendLine($"Current Branch: {CurrentBranch}");
    sb.AppendLine("Branches:");

    foreach (var branch in Branches) {
      sb.Append($"  - {branch.Name} (Current: {branch.IsCurrentBranch}, Has Changes: {branch.HasChanges}, Remote Ahead: {branch.IsRemoteAhead}, Local Ahead: {branch.IsLocalAhead})");
      sb.AppendLine();
      if (branch.HasChanges) {
        sb.AppendLine("    Unstaged Changes:");
        foreach (var file in branch.UnstagedChangedFilePaths) {
          sb.AppendLine($"        {file}");
        }
      }
    }
    return sb.ToString();
  }
  #endregion

  #region Git Commands ---------------------------------------------------------
  private string GetCurrentBranch() => GH.Run("rev-parse --abbrev-ref HEAD", Path);

  private string[] GetAllBranches() => GH.Run("branch --list --format='%(refname:short)'", Path)
    .SplitLines()
    .Select(b => b.Trim('\'', '*', ' '))
    .ToArray();

  private void FetchAll() {
    GH.Run("fetch --all", Path);
  }
  #endregion
}