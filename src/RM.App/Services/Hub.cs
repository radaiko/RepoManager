using Photino.NET;
using RM.UI;

namespace RM.App.Services;

public static class Hub {
  public static PhotinoWindow? Window { get; set; }
  public static Settings Settings => _settings ??= Settings.Load();
  private static Settings? _settings;
}