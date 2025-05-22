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

  public static void RunInBackground(Action action) => Task.Run(action);
}
