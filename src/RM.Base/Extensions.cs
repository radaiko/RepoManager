namespace RM.Base;

public static class Extensions {
  #region String Extensions ----------------------------------------------------
  public static bool IsBlank(this string? str) {
    return string.IsNullOrEmpty(str);
  }
  public static bool IsNotBlank(this string? str) {
    return !str.IsBlank();
  }
  public static bool IsDigit(this string? str) {
    return str != null && str.IsNotBlank() && str.All(char.IsDigit);
  }
  public static int ToInt(this string? str) {
    if (str.IsBlank()) return 0;
    var trimmed = str?.Replace("\r", "").Replace("\n", "").Trim();
    if (trimmed.IsDigit()) return Convert.ToInt32(trimmed);
    Logger.Error($"String '{trimmed}' is not a valid integer.");
    throw new ArgumentException($"String '{trimmed}' is not a valid integer.");
  }
  public static string[] SplitLines(this string str) {
    return str.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries);
  }
  #endregion
}