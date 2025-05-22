using Microsoft.Extensions.DependencyInjection;
using MudBlazor.Services;
using Photino.Blazor;
using RM.App.Helpers;
using RM.App.Services;
using RM.Base;
using Common = RM.Base.Common;

namespace RM.App {
  class Program {
    [STAThread]
    static void Main(string[] args) {
      // Logger
      Logger.LogLevel = LogLevel.Info;
      Logger.LogLevel = Hub.Settings.LogLevel;
      Logger.LogToFile = Hub.Settings.LogToFile;

      var appBuilder = PhotinoBlazorAppBuilder.CreateDefault(args);

      appBuilder.Services.AddLogging();
      appBuilder.Services.AddMudServices();

      appBuilder.RootComponents.Add<Components.App>("app");

      var app = appBuilder.Build();

      app.MainWindow.SetTitle("Repo Manager");
      app.MainWindow.SetContextMenuEnabled(true);
      WindowManager.SetMainWindow(app.MainWindow);

      AppDomain.CurrentDomain.UnhandledException += (_, error) => {
        app.MainWindow.ShowMessage("Fatal Exception", error.ExceptionObject.ToString());
        Logger.Error("Fatal Exception", (Exception)error.ExceptionObject);
      };


      Logger.Info("Starting Repo Manager");
      Logger.Info($"AppData: {Common.GetAppDataPath()}");
      Logger.Info($"LogLevel: {Logger.LogLevel}");
      Logger.Info($"LogToFile: {Logger.LogToFile}");
      Logger.Info($"LogToConsole: {Logger.LogToConsole}");

      app.Run();
    }
  }
}
