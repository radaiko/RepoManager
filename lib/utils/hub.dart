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
      addFolder(folderPath);
    }
    isInitialized = true;
    Logger.info('Hub initialized successfully.');
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

  static void analyze() {
    Logger.info('Analyzing all folders...');
    for (var folder in _folders) {
      for (var repo in folder.repos) {
        repo.analyze();
      }
    }
    Logger.info('Analysis completed for all folders.');
  }
}
