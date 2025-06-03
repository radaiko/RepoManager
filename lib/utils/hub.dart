import 'package:repo_manager/logic/folder.dart';
import 'package:repo_manager/utils/auto_analyzer.dart';
import 'package:repo_manager/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Hub {
  // ---------------------------------------------------------------------------
  // Variables
  // ---------------------------------------------------------------------------
  static bool isInitialized = false;
  static final List<Folder> _folders = [];
  static List<Folder> get folders => _folders;
  static SharedPreferences? _prefs;
  static SharedPreferences? get prefs => _prefs;

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------
  static Future<void> initialize() async {
    if (isInitialized) {
      Logger.info('Hub is already initialized.');
      return;
    }
    Logger.info('Initializing Hub...');
    Logger.info('Initialize shared preferences...');
    _prefs = await SharedPreferences.getInstance();
    Logger.info('Loading folders from storage...');
    _folders.clear();
    List<String> savedFolders = _prefs?.getStringList('watch_folders') ?? [];
    for (String folderPath in savedFolders) {
      _addFolderWithoutAnalysis(folderPath);
    }
    isInitialized = true;
    Logger.info('Hub initialized successfully.');

    // Start progressive analysis in the background after initialization
    if (_folders.isNotEmpty) {
      Future.microtask(() => startProgressiveAnalysis());
    }
  }

  // Repo management
  static void addFolder(String folder) {
    Logger.info('Adding folder: $folder');
    _prefs?.setStringList(
      'watch_folders',
      _folders.map((f) => f.path).toList()..add(folder),
    );
    _folders.add(Folder(folder));
    AutoAnalyzer.notify();

    // Start analysis for the newly added folder
    Future.microtask(() => _folders.last.startProgressiveAnalysis());
  }

  /// Adds a folder without triggering immediate analysis (used during initialization)
  static void _addFolderWithoutAnalysis(String folder) {
    Logger.info('Adding folder (no immediate analysis): $folder');
    _folders.add(Folder(folder));
  }

  static void removeFolder(String folder) {
    Logger.info('Removing folder: $folder');
    _prefs?.setStringList(
      'watch_folders',
      _folders.map((f) => f.path).toList()..remove(folder),
    );
    _folders.removeWhere((f) => f.path == folder);
    AutoAnalyzer.notify();
  }

  static Future<void> analyze() async {
    Logger.info('Analyzing all folders...');
    for (var folder in _folders) {
      for (var repo in folder.repos) {
        await repo.analyze();
      }
    }
    Logger.info('Analysis completed for all folders.');
  }

  /// Starts progressive analysis of all folders and repos
  /// This analyzes repos one by one to keep the UI responsive
  static Future<void> startProgressiveAnalysis() async {
    Logger.info('Starting progressive analysis of all folders...');

    for (int folderIndex = 0; folderIndex < _folders.length; folderIndex++) {
      final folder = _folders[folderIndex];
      Logger.debug(
        'Progressive analysis: folder ${folderIndex + 1}/${_folders.length} - ${folder.path}',
      );

      await folder.startProgressiveAnalysis();

      // Small delay between folders to keep UI responsive
      if (folderIndex < _folders.length - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    Logger.info('Progressive analysis completed for all folders.');
  }
}
