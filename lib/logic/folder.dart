import 'dart:io';
import 'package:repo_manager/logic/repo.dart';
import 'package:repo_manager/utils/extensions.dart';
import 'package:repo_manager/utils/logger.dart';

class Folder {
  // ---------------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------------
  final String path;

  final List<Repo> _repos = [];
  List<Repo> get repos => _repos;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  Folder(this.path) {
    _initRepos();
  }

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------

  /// Starts progressive analysis of all repos in this folder
  Future<void> startProgressiveAnalysis() async {
    Logger.info('Starting progressive analysis for folder: $path');

    // Analyze repos one by one with small delays to keep UI responsive
    for (int i = 0; i < _repos.length; i++) {
      final repo = _repos[i];
      Logger.debug(
        'Progressive analysis: ${i + 1}/${_repos.length} - ${repo.name}',
      );

      await repo.analyze();

      // Small delay between repos to keep UI responsive
      if (i < _repos.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    Logger.info('Progressive analysis completed for folder: $path');
  }

  // ---------------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------------
  Future<void> _initRepos() async {
    _repos.addAll(await _getReposInFolder());
  }

  Future<List<Repo>> _getReposInFolder() async {
    Logger.debug('Starting to scan folder for repositories: $path');
    var sw = Stopwatch()..start();
    var repos = <Repo>[];

    // Request storage permission before accessing directories
    if (Platform.isMacOS) {
      Logger.debug('Running on macOS, checking directory access permissions');
      try {
        // Test directory access by checking if we can list the root directory
        await Directory(path).list().first;
        Logger.debug('Directory access confirmed for: $path');
      } catch (e) {
        Logger.errorWithException(
          'Directory access failed for: $path',
          Exception(e),
        );
        throw Exception(
          'Cannot access directory: $path. Please grant file access permissions in System Settings > Privacy & Security > Files and Folders.',
        );
      }
    }

    // Find all .git directories
    Logger.debug('Scanning for .git directories in: $path');
    var gitDirs = <String>[];
    for (var entity in Directory(path).listSync(recursive: true)) {
      if (entity is Directory && entity.path.endsWith('.git')) {
        gitDirs.add(entity.path);
        Logger.debug('Found git repository: ${entity.path}');
      }
    }
    Logger.debug('Found ${gitDirs.length} git repositories');

    // Process directories in parallel using isolates
    Logger.debug('Creating repository instances');
    for (var dir in gitDirs) {
      var repoPath = Directory(dir).parent.path;
      Logger.debug('Creating Repo instance for: $repoPath');
      repos.add(Repo(repoPath: repoPath));
    }

    sw.stop();
    Logger.debug(
      'Completed scanning folder in ${sw.elapsedHumanReadable}. Found ${repos.length} repositories',
    );
    return repos;
  }
}
