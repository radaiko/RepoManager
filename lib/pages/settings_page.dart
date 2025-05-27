import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:repo_manager/utils/hub.dart';
import '../utils/logger.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> _watchFolders = [];
  bool _loggingActive = true;
  LogLevel _selectedLogLevel = LogLevel.info;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = Hub.prefs;

    setState(() {
      _watchFolders = prefs?.getStringList('watch_folders') ?? [];
      _loggingActive = Logger.logToFile;
      _selectedLogLevel = Logger.logLevel;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = Hub.prefs;
    await prefs?.setBool('log_to_file', Logger.logToFile);
    await prefs?.setBool('log_to_console', Logger.logToConsole);
    await prefs?.setString('log_level', _selectedLogLevel.name);
  }

  Future<void> _addFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null &&
        !_watchFolders.contains(selectedDirectory)) {
      setState(() {
        _watchFolders.add(selectedDirectory);
      });
      Hub.addFolder(selectedDirectory);
    }
  }

  Future<void> _removeFolder(String folder) async {
    setState(() {
      _watchFolders.remove(folder);
    });
    Hub.removeFolder(folder);
  }

  void _updateLoggingActive(bool value) async {
    setState(() {
      _loggingActive = value;
      Logger.logToFile = value;
    });
    await _savePrefs();
  }

  void _updateLogLevel(LogLevel? level) async {
    if (level != null) {
      setState(() {
        _selectedLogLevel = level;
        Logger.logLevel = level;
      });
    }
    await _savePrefs();
  }

  Future<void> _openLogFile() async {
    await Logger.openLogFile();
  }

  String _getLogLevelDisplayName(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return 'Error';
      case LogLevel.info:
        return 'Info';
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.debugGit:
        return 'Debug Git';
    }
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug("Building SettingsPage");
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Watch List Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Watch List',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        ElevatedButton.icon(
                          onPressed: _addFolder,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Folder'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_watchFolders.isEmpty)
                      const Text(
                        'No folders added yet. Click "Add Folder" to add a folder to watch.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      )
                    else
                      ..._watchFolders.map(
                        (folder) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text(
                              folder,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFolder(folder),
                              tooltip: 'Remove folder',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Debug Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    // Open Log Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openLogFile,
                        icon: const Icon(Icons.description),
                        label: const Text('Open Log'),
                        style: ElevatedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Logging Active Checkbox
                    CheckboxListTile(
                      title: const Text('Logging Active'),
                      value: _loggingActive,
                      onChanged: (value) =>
                          _updateLoggingActive(value ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),

                    // Log Level Dropdown
                    Row(
                      children: [
                        const Text(
                          'Log Level: ',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<LogLevel>(
                          value: _selectedLogLevel,
                          onChanged: _updateLogLevel,
                          items: LogLevel.values.map((LogLevel level) {
                            return DropdownMenuItem<LogLevel>(
                              value: level,
                              child: Text(_getLogLevelDisplayName(level)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
