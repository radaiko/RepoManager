namespace RM.Playground;

public class Branch(Repo owner, string name) {
  public string Name { get; set; } = name;
  public bool IsCurrentBranch => owner.CurrentBranch == Name;
  public bool HasChanges => InternalHasChanges();
  
  public bool HasUnmergedChanges { get; set; }
  public bool HasUnpushedChanges { get; set; }
  public bool HasUnpulledChanges { get; set; }
  
  #region Git Commands ---------------------------------------------------------
  private bool InternalHasChanges() {
    var output = Common.RunGitCommand($"status --short {Name}", owner.Path);
    return !string.IsNullOrWhiteSpace(output);
  }
  #endregion
}