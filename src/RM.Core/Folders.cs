using System.Diagnostics;
using RM.Base;

namespace RM.Core;

public class Folders {
  #region Variables ------------------------------------------------------------
  private List<Folder> _foldersList = [];
  #endregion

  #region Interface ------------------------------------------------------------
  public void AddFolder(string path) {
    if (string.IsNullOrEmpty(path)) return;
    if (path.EndsWith("/") || path.EndsWith("\\")) path = path.Substring(0, path.Length - 1);
    if (!Directory.Exists(path)) return;
    var folder = new Folder(path);
    _foldersList.Add(folder);
  }

  public void RemoveFolder(string path) {
    if (string.IsNullOrEmpty(path)) return;
    if (path.EndsWith("/") || path.EndsWith("\\")) path = path.Substring(0, path.Length - 1);
    var folder = _foldersList.FirstOrDefault(f => f.Path == path);
    if (folder == null) return;
    _foldersList.Remove(folder);
  }

  public string[] GetFolderPaths() => _foldersList.Select(f => f.Path).ToArray();

  public List<Folder> GetAll() => _foldersList;

  public void Analyze() {
    var sw = new Stopwatch(); sw.Start();
    Parallel.ForEach(_foldersList, folder => {
      folder.Analyze();
    });
    sw.Stop();
    Logger.Debug($"Analyzed all folders in {sw.ElapsedMilliseconds} ms");
  }
  #endregion
}