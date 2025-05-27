import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:repo_manager/utils/hub.dart';
import 'package:repo_manager/utils/auto_analyzer.dart';
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
  bool _autoAnalysisEnabled = false;
  int _analysisInterval = 1;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // Start a timer to update the UI every second when auto analysis is enabled
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_autoAnalysisEnabled && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = Hub.prefs;

    setState(() {
      _watchFolders = prefs?.getStringList('watch_folders') ?? [];
      _loggingActive = Logger.logToFile;
      _selectedLogLevel = Logger.logLevel;
      _autoAnalysisEnabled = AutoAnalyzer.isAutoAnalysisEnabled;
      _analysisInterval = AutoAnalyzer.analysisIntervalMinutes;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = Hub.prefs;
    await prefs?.setBool('log_to_file', Logger.logToFile);
    await prefs?.setBool('log_to_console', Logger.logToConsole);
    await prefs?.setString('log_level', _selectedLogLevel.name);
    await prefs?.setBool('auto_analysis_enabled', _autoAnalysisEnabled);
    await prefs?.setInt('analysis_interval_minutes', _analysisInterval);
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

  void _updateAutoAnalysis(bool value) async {
    setState(() {
      _autoAnalysisEnabled = value;
    });

    if (value) {
      AutoAnalyzer.startAutoAnalysis();
    } else {
      AutoAnalyzer.stopAutoAnalysis();
    }

    await _savePrefs();
  }

  void _updateAnalysisInterval(int value) async {
    setState(() {
      _analysisInterval = value;
    });

    AutoAnalyzer.setAnalysisInterval(value);
    await _savePrefs();
  }

  Future<void> _openLogFile() async {
    await Logger.openLogFile();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} min';
    } else if (difference.inSeconds > 0) {
      return 'in ${difference.inSeconds} sec';
    } else if (difference.inMinutes < 0 && difference.inMinutes > -60) {
      return '${(-difference.inMinutes)} min ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
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

            // Auto Analysis Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatic Analysis',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    // Auto Analysis Toggle
                    CheckboxListTile(
                      title: const Text('Enable Automatic Analysis'),
                      subtitle: const Text(
                        'Automatically analyze repositories in the background',
                      ),
                      value: _autoAnalysisEnabled,
                      onChanged: (value) => _updateAutoAnalysis(value ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),

                    if (_autoAnalysisEnabled) ...[
                      const SizedBox(height: 16),

                      // Analysis Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analysis Status',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (AutoAnalyzer.isAnalyzing)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Analyzing repositories...'),
                                ],
                              )
                            else if (AutoAnalyzer.lastAnalysisTime != null) ...[
                              Text(
                                'Last analysis: ${_formatDateTime(AutoAnalyzer.lastAnalysisTime!)}',
                              ),
                              if (AutoAnalyzer.nextAnalysisTime != null)
                                Text(
                                  'Next analysis: ${_formatDateTime(AutoAnalyzer.nextAnalysisTime!)}',
                                ),
                            ] else
                              const Text('No analysis performed yet'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Analysis Interval Slider
                      Text(
                        'Analysis Interval: $_analysisInterval minutes',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Slider(
                        value: _analysisInterval.toDouble(),
                        min: 1,
                        max: 60,
                        divisions: 59, // 1 to 60 minutes = 59 steps
                        label: '$_analysisInterval min',
                        onChanged: (value) {
                          _updateAnalysisInterval(value.round());
                        },
                      ),
                      const SizedBox(height: 8),

                      // Manual Analysis Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            AutoAnalyzer.performManualAnalysis();
                          },
                          icon: const Icon(Icons.analytics),
                          label: const Text('Analyze Now'),
                          style: ElevatedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ),
                    ],
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
                    const SizedBox(height: 16),

                    // Auto Analysis Section
                    Row(
                      children: [
                        const Text(
                          'Auto Analysis: ',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        Switch(
                          value: _autoAnalysisEnabled,
                          onChanged: _updateAutoAnalysis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Analysis Interval Slider
                    Row(
                      children: [
                        const Text(
                          'Analysis Interval (m): ',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _analysisInterval.toDouble(),
                            onChanged: (value) =>
                                _updateAnalysisInterval(value.toInt()),
                            min: 1,
                            max: 60,
                            divisions: 11,
                            label: _analysisInterval.toString(),
                          ),
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
