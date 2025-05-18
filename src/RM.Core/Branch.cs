using System.Diagnostics;
using RM.Base;

namespace RM.Core;

/// <summary>Represent a git branch in a repo</summary>
public class Branch {
  #region Properties -----------------------------------------------------------
  public long LastAnalyzeTime { get; private set; }
  public bool IsAnalyzed => LastAnalyzeTime > 0;
  public string Name { get; set; }
  public bool IsCurrentBranch => _owner.CurrentBranch == Name;
  public bool IsRemoteAhead => _commitsToPull > 0;
  public bool IsLocalAhead => _commitsToPush > 0;
  public string[] UnstagedChangedFilePaths => _unstagedChangedFilePaths;
  public string?[] UnstagedChangeFileNames => UnstagedChangedFilePaths.Select(Path.GetFileName).ToArray();
  public bool HasChanges => UnstagedChangeFileNames.Length > 0;
  #endregion
  
  #region Variables ------------------------------------------------------------
  private string[] _unstagedChangedFilePaths = [];
  private string[] _untrackedFilePaths = [];
  private int _commitsToPull = -1;
  private int _commitsToPush = -1;
  private readonly Repo _owner;
  private bool _hasRemote = false;
  #endregion
  
  #region Constructor --------------------------------------------------------
  public Branch(Repo owner, string name) {
    _owner = owner;
    Name = name;
  }
  #endregion
  
  #region Interface ------------------------------------------------------------
  public void Analyze() {
    var sw = new Stopwatch(); sw.Start();

    _unstagedChangedFilePaths = GH.Run($"diff --name-only {Name}", _owner.Path).SplitLines();
    _untrackedFilePaths = GH.Run($"ls-files --others --exclude-standard", _owner.Path).SplitLines();
    
    _hasRemote = GH.Run($"ls-remote --heads origin {Name}", _owner.Path).Length > 0;
    if (_hasRemote) {
      _commitsToPull = GH.Run($"rev-list --count {Name}..origin/{Name}", _owner.Path).ToInt();
      _commitsToPush = GH.Run($"rev-list --count origin/{Name}..{Name}", _owner.Path).ToInt();
    }
    sw.Stop();
    LastAnalyzeTime = sw.ElapsedMilliseconds;
  }
  public string GetDiff(string diffBranch = "HEAD") => GH.Run($"diff {diffBranch} {Name}", _owner.Path);

  public string[] GetDiffArray(string diffBranch = "HEAD") => GetDiff().SplitLines();
  #endregion
}
  
