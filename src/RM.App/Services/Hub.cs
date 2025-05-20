using Photino.NET;
using RM.Base;
using RM.Core;
using RM.UI;

namespace RM.App.Services;

public static class Hub {
  static Hub() {
    foreach (var folder in Settings.Folders) {
      InternalAddFolder(folder);
    }
    _autoRefresher = new AutoRefresher(Folders);
    _autoRefresher.OnStateChanged += () => {
      try {
        if (Window != null) {
          Window.Invoke(() => {
            try {
              OnStateChanged?.Invoke();
            } catch (Exception ex) {
              Logger.Error("Error invoking OnStateChanged:", ex);
            }
          });
        }
      } catch (Exception ex) {
        Logger.Error("Error in Window.Invoke:", ex);
      }
    };
    _autoRefresher.Start();
  }
  public static PhotinoWindow? Window { get; set; }
  public static Settings Settings => _settings ??= Settings.Load();
  private static Settings? _settings;
  private static AutoRefresher? _autoRefresher;

  public static event Action? OnStateChanged;

  #region Folders Handling -----------------------------------------------------
  public static Folders Folders { get; } = new();
  private static void InternalAddFolder(string path) {
    Folders.AddFolder(path);
  }
  public static void AddFolder(string path) {
    InternalAddFolder(path);
    Settings.Folders.Add(path);
    Settings.Save();
  }
  private static void InternalRemoveFolder(string path) {
    Folders.RemoveFolder(path);
  }
  public static void RemoveFolder(string path) {
    InternalRemoveFolder(path);
    Settings.Folders.Remove(path);
    Settings.Save();
  }
  #endregion
}