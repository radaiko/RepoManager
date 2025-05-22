using Photino.NET;
using RM.App.Helpers;
using RM.Base;
using RM.Core;
using RM.UI;

namespace RM.App.Services;

public static class Hub {
  static Hub() {
    foreach (var folder in Settings.Folders) {
      InternalAddFolder(folder);
    }
    Logger.Info($"Loaded {Settings.Folders.Count} folders from settings");
    _autoRefresher = new AutoRefresher(Folders);
    _autoRefresher.OnStateChanged += () => {
      try {
        WindowManager.MainWindow?.Invoke(() => {
          OnAutoRefresherStateChanged?.Invoke();
        });
      } catch (Exception ex) {
        Logger.Error("Error in Invoke:", ex);
      }
    };
    _autoRefresher.Start();
    Logger.Info("AutoRefresher started");
    Logger.Info("Hub initialized");
  }
  public static Settings Settings => _settings ??= Settings.Load();
  private static Settings? _settings;
  private static AutoRefresher? _autoRefresher;

  public static event Action? OnAutoRefresherStateChanged;

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
