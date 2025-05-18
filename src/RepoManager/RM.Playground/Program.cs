namespace RM.Playground;

class Program {
  static void Main(string[] args) {
    if (args.Length == 0) {
      Console.WriteLine("Please provide a path to a git repository.");
      return;
    }
    
    var repoPath = Environment.ExpandEnvironmentVariables(args[0].Replace("~", Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)));
    Repo repo = new Repo(repoPath);
    
    Console.WriteLine($"Repository: {repo.Name}");
    Console.WriteLine($"Current Branch: {repo.CurrentBranch}");
    
    foreach (var branch in repo.Branches) {
      Console.WriteLine($"Branch: {branch.Name}, Has Changes: {branch.HasChanges}");
    }
  }
}