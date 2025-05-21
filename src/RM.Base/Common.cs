using System.Text.Json;
using System.Text.Json.Serialization;

namespace RM.Base;

public static class Common {
  public static string GetAppDataPath() => Path.Combine(
      Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
      "RepoManager"
    );

  public static JsonSerializerOptions JsSOptions() => new() {
    WriteIndented = true,
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
  };

  public static Action<EventHandler> RunInBackground(Action action)
  {
    EventHandler? completed = null;
    Task.Run(() =>
    {
      action();
      completed?.Invoke(null, EventArgs.Empty);
    });
    return handler => completed += handler;
  }
}
