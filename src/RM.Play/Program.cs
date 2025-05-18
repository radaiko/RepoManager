using RM.Base;
using RM.Core;

namespace RM.Playground;

class Program {
  static void Main(string[] args) {
    Logger.LogLevel = LogLevel.Debug;
    Logger.LogToConsole = true;
    Logger.LogToFile = false;
    
    if (args.Length == 0) {
      Console.WriteLine("Please provide a path to a git repository.");
      return;
    }
    var folderPath = Environment.ExpandEnvironmentVariables(args[0].Replace("~", Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)));
    var folder = new Folder(folderPath);
    
    Console.WriteLine($"{folder.Repos.Count} repositories found in {folderPath} with {folder.Repos.Sum(r => r.Branches.Count)} branches in {folder.LastAnalyzeTime} ms");
    // for (int i = 0; i < folder.Repos.Count; i++) {
    //   Console.WriteLine($"{i} = {folder.Repos[i].LastAnalyzeTime}");
    // }
    
    
    Console.WriteLine("Press any key to start analyze");
    Console.ReadKey();
    Console.WriteLine($"Analyzing folder: {folderPath}");
    folder.Analyze();
    Console.WriteLine($"Analyzed {folder.Repos.Count} repositories in {folder.LastAnalyzeTime} ms");
    
    Console.WriteLine("Press any key to show results");
    Console.ReadKey();
    // foreach (var repo in folder.Repos) {
    //   Console.WriteLine(repo.ToString());
    // }
  }
  
}