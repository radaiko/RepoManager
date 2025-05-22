using Photino.NET;

namespace RM.App.Helpers;

public static class WindowManager {
  public static PhotinoWindow? MainWindow { get; private set; }

  public static void SetMainWindow(PhotinoWindow? window) => MainWindow = window;
}
