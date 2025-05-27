import 'package:repo_manager/utils/extensions.dart';
import 'package:repo_manager/utils/git.dart';
import 'package:repo_manager/utils/logger.dart';

// -------------------------------------------------------------------------------------------------
// Repo class
// -------------------------------------------------------------------------------------------------
class Repo {
  // ---------------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------------
  final String _path;
  String get path => _path;

  final String _name;
  String get name => _name;

  String _mainBranchName = "master";
  String get mainBranchName => _mainBranchName;

  String _currentBranch = "";
  String get currentBranch => _currentBranch;

  List<Branch> branches = [];

  bool get isMainUpToDate =>
      !mainBranch.isRemoteAhead && !mainBranch.isLocalAhead;

  Branch get mainBranch => branches.firstWhere(
    (b) => b.name.toLowerCase() == _mainBranchName.toLowerCase(),
    orElse: () => Branch(this, _mainBranchName),
  );

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  Repo({required String repoPath})
    : _path = repoPath.endsWith("/") || repoPath.endsWith("\\")
          ? repoPath.substring(0, repoPath.length - 1)
          : repoPath,
      _name = repoPath.getFileName() {
    _initializeRepo();
  }

  void _initializeRepo() async {
    Logger.debug("Initializing repo $name...");
    var sw = Stopwatch();
    sw.start();
    _fetchAll();
    _currentBranch = await _getCurrentBranch();
    Logger.debug("Current branch for repo $name is $_currentBranch");
    var branches = await _getAllBranches();
    Logger.debug("Found ${branches.length} branches in repo $name");
    for (var branch in branches) {
      this.branches.add(Branch(this, branch));
    }
    // check if main branch exists
    if (this.branches.any((b) => b.name.toLowerCase() == "main")) {
      _mainBranchName = "main";
    } else {
      _mainBranchName = "master";
    }
    sw.stop();
    Logger.debug(
      "Repo $name created and pre analyzed in ${sw.elapsedHumanReadable}",
    );
  }

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------
  void analyze() {
    Logger.info("Analyzing all branches for repo $name...");
    var sw = Stopwatch();
    sw.start();
    for (var branch in branches) {
      branch.analyze();
    }
    sw.stop();
    Logger.info(
      "Analysis completed for repo $name in ${sw.elapsedHumanReadable} s",
    );
  }

  // ---------------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------------
  Future<List<String>> _getAllBranches() async =>
      await Git.getAllBranches(_path);

  Future<String> _getCurrentBranch() async => Git.getCurrentBranch(_path);

  void _fetchAll() {
    Git.fetchAll(_path);
    Logger.debug("Fetching all branches for repo $name");
  }
}

// -------------------------------------------------------------------------------------------------
// Branch class
// -------------------------------------------------------------------------------------------------
class Branch {
  // ---------------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------------
  final String _name;
  String get name => _name;

  List<String> _unstagedChangedFilePaths = [];
  List<String> get unstagedChangedFilePaths => _unstagedChangedFilePaths;

  List<String> get unstagedChangedFileNames =>
      _unstagedChangedFilePaths.map((path) => path.getFileName()).toList();

  List<String> _untrackedFilePaths = [];
  List<String> get untrackedFilePaths => _untrackedFilePaths;

  int _commitsToPull = -1;
  int get commitsToPull => _commitsToPull;

  int _commitsToPush = -1;
  int get commitsToPush => _commitsToPush;

  bool get isRemoteAhead => _commitsToPull > 0;
  bool get isLocalAhead => _commitsToPush > 0;

  // ---------------------------------------------------------------------------
  // Variables
  // ---------------------------------------------------------------------------
  final Repo _owner;
  bool _hasRemote = false;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  Branch(this._owner, this._name);

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------
  @override
  String toString() {
    return 'Branch{name: $name}';
  }

  void analyze() async {
    var sw = Stopwatch();
    sw.start();
    _unstagedChangedFilePaths = await Git.getUnstagedFilePaths(_owner.path);
    _untrackedFilePaths = await Git.getUntrackedFiles(_owner.path);
    _hasRemote = await Git.checkIfHasRemote(_owner.path, _name);
    if (_hasRemote) {
      _commitsToPull = await Git.getCommitsToPull(_owner.path);
      _commitsToPush = await Git.getCommitsToPush(_owner.path);
    }
    sw.stop();
    Logger.debug(
      "Branch $name in repo ${_owner.name} analyzed in ${sw.elapsedHumanReadable} s",
    );
  }

  // ---------------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------------
}
