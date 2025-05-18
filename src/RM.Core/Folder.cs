using System.Diagnostics;

namespace RM.Core;

public class Folder{
  
  #region Properties -----------------------------------------------------------
  public List<Repo> Repos { get; private set; }
  public long LastAnalyzeTime { get; private set;}
  #endregion
  
  #region Variables ------------------------------------------------------------
  private string _path;
  #endregion
  
  #region Constructor ----------------------------------------------------------
  public Folder(string path) {
    _path = path;
    Repos = GetAllRepos();
  }
  #endregion
  
  #region Analyze --------------------------------------------------------------
  public void Analyze() {
    var sw = new Stopwatch(); sw.Start();
    Parallel.ForEach(Repos, repo => {
      repo.Analyze();
    });
    sw.Stop();
    LastAnalyzeTime = sw.ElapsedMilliseconds;
  }
  #endregion
  
  #region Implementation -------------------------------------------------------
  private List<Repo> GetAllRepos() {
    var sw = new Stopwatch(); sw.Start();
    var directories = Directory.GetDirectories(_path, ".git", System.IO.SearchOption.AllDirectories);
    var repos = new List<Repo>();
    Parallel.ForEach(directories, dir => {
      var repo = GetRepo(dir);
      repos.Add(repo);
    });
    sw.Stop();
    LastAnalyzeTime = sw.ElapsedMilliseconds;
    return repos;
  }
  private static Repo GetRepo(string path) {
    var repoPath = Environment.ExpandEnvironmentVariables(path.Replace("~", Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)));
    if (repoPath.EndsWith(".git"))
      repoPath = repoPath.Substring(0, repoPath.Length - 4);
    return new Repo(repoPath);
  }
  #endregion
  
}