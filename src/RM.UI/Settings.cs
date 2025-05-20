using System.Text.Json;
using RM.Base;

namespace RM.UI;

public class Settings {
  #region Properties -----------------------------------------------------------
  public List<string> Folders { get; set; } = new List<string>();

  private LogLevel _logLevel;

  public LogLevel LogLevel {
    get => _logLevel;
    set {
      if (_logLevel != value) {
        _logLevel = value;
        Save();
      }
    }
  }

  private bool _logToFile;

  public bool LogToFile {
    get => _logToFile;
    set {
      if (_logToFile != value) {
        _logToFile = value;
        Save();
      }
    }
  }
  #endregion

  #region Variables ------------------------------------------------------------
  private static string _settingsPath = Path.Combine(Common.GetAppDataPath(), "settings.json");
  #endregion

  #region Interface ------------------------------------------------------------
  public static Settings Load() {
    var file = _settingsPath;
    if (!File.Exists(file)) return new Settings();
    var fileContent = File.ReadAllText(file);
    try {
      var settings = JsonSerializer.Deserialize<Settings>(fileContent, Common.JsSOptions());
      if (settings == null) {
        Logger.Error("Settings file is empty or invalid");
        return new Settings();
      }
      Logger.Info($"Settings loaded from {file}");
      return settings;
    }
    catch (JsonException e) {
      Logger.Error("Settings file is invalid", e.ToString());
      return new Settings();
    }
  }

  public void Save() {
    var file = _settingsPath;
    if (!Directory.Exists(Common.GetAppDataPath()))
      Directory.CreateDirectory(Common.GetAppDataPath());
    File.WriteAllText(file, JsonSerializer.Serialize(this, Common.JsSOptions()));
    Logger.Info($"Settings saved to {file}");
  }
  #endregion
}