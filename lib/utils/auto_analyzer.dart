import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:repo_manager/utils/hub.dart';
import 'package:repo_manager/utils/logger.dart';

class AutoAnalyzer {
  // ---------------------------------------------------------------------------
  // Variables
  // ---------------------------------------------------------------------------
  static Timer? _analysisTimer;
  static bool _isAnalyzing = false;
  static bool _isAutoAnalysisEnabled = false;
  static int _analysisIntervalMinutes = 1; // Default to 1 minute
  static DateTime? _lastAnalysisTime;
  static DateTime? _nextAnalysisTime;

  // Event listeners for UI updates
  static final List<VoidCallback> _onAnalysisStartedListeners = [];
  static final List<VoidCallback> _onAnalysisCompletedListeners = [];

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  static bool get isAutoAnalysisEnabled => _isAutoAnalysisEnabled;
  static bool get isAnalyzing => _isAnalyzing;
  static int get analysisIntervalMinutes => _analysisIntervalMinutes;
  static DateTime? get lastAnalysisTime => _lastAnalysisTime;
  static DateTime? get nextAnalysisTime => _nextAnalysisTime;

  // ---------------------------------------------------------------------------
  // Event handling
  // ---------------------------------------------------------------------------
  static void addOnAnalysisStartedListener(VoidCallback listener) {
    _onAnalysisStartedListeners.add(listener);
  }

  static void removeOnAnalysisStartedListener(VoidCallback listener) {
    _onAnalysisStartedListeners.remove(listener);
  }

  static void addOnAnalysisCompletedListener(VoidCallback listener) {
    _onAnalysisCompletedListeners.add(listener);
  }

  static void removeOnAnalysisCompletedListener(VoidCallback listener) {
    _onAnalysisCompletedListeners.remove(listener);
  }

  static void _notifyAnalysisStarted() {
    for (var listener in _onAnalysisStartedListeners) {
      try {
        listener();
      } catch (e) {
        Logger.error('Error in analysis started listener: $e');
      }
    }
  }

  static void _notifyAnalysisCompleted() {
    for (var listener in _onAnalysisCompletedListeners) {
      try {
        listener();
      } catch (e) {
        Logger.error('Error in analysis completed listener: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------
  static void notify() {
    Logger.debug('Analysis completed, notifying listeners...');
    _notifyAnalysisCompleted();
  }

  static void startAutoAnalysis() {
    Logger.info('Starting automatic repository analysis...');
    _isAutoAnalysisEnabled = true;

    // Save to preferences
    _saveSettings();

    // Start immediate analysis
    _performAnalysis();

    // Schedule periodic analysis
    _scheduleNextAnalysis();
  }

  static void stopAutoAnalysis() {
    if (!_isAutoAnalysisEnabled) {
      Logger.info('Auto analysis is already disabled.');
      return;
    }

    Logger.info('Stopping automatic repository analysis...');
    _isAutoAnalysisEnabled = false;

    // Save to preferences
    _saveSettings();

    _analysisTimer?.cancel();
    _analysisTimer = null;
  }

  static void setAnalysisInterval(int minutes) {
    if (minutes < 1 || minutes > 60) {
      Logger.error('Analysis interval must be between 1 and 60 minutes.');
      return;
    }

    _analysisIntervalMinutes = minutes;
    Logger.info('Analysis interval set to $_analysisIntervalMinutes minutes.');

    // Save to preferences
    _saveSettings();

    // Restart timer if auto analysis is enabled
    if (_isAutoAnalysisEnabled) {
      _analysisTimer?.cancel();
      _scheduleNextAnalysis();
    }
  }

  static Future<void> performManualAnalysis() async {
    Logger.info('Performing manual repository analysis...');
    await _performAnalysis();
  }

  // ---------------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------------
  static Future<void> _saveSettings() async {
    if (Hub.isInitialized && Hub.prefs != null) {
      await Hub.prefs?.setBool('auto_analysis_enabled', _isAutoAnalysisEnabled);
      await Hub.prefs?.setInt(
        'analysis_interval_minutes',
        _analysisIntervalMinutes,
      );
    }
  }

  static void _scheduleNextAnalysis() {
    if (!_isAutoAnalysisEnabled) return;

    _nextAnalysisTime = DateTime.now().add(
      Duration(minutes: _analysisIntervalMinutes),
    );

    _analysisTimer = Timer(Duration(minutes: _analysisIntervalMinutes), () {
      _performAnalysis();
      _scheduleNextAnalysis(); // Schedule the next analysis
    });

    Logger.debug('Next analysis scheduled for $_nextAnalysisTime.');
  }

  static Future<void> _performAnalysis() async {
    if (_isAnalyzing) {
      Logger.debug('Analysis already in progress, skipping...');
      return;
    }

    if (!Hub.isInitialized) {
      Logger.error('Hub is not initialized, skipping analysis.');
      return;
    }

    if (Hub.folders.isEmpty) {
      Logger.debug('No folders to analyze, skipping...');
      return;
    }

    try {
      _isAnalyzing = true;
      _lastAnalysisTime = DateTime.now();
      _notifyAnalysisStarted();

      Logger.info('Starting automatic analysis of all repositories...');
      final sw = Stopwatch()..start();

      // Perform the progressive analysis to keep UI responsive
      await Hub.startProgressiveAnalysis();

      sw.stop();
      Logger.info(
        'Automatic analysis completed in ${sw.elapsedMilliseconds}ms.',
      );
    } catch (e) {
      Logger.error('Error during automatic analysis: $e');
    } finally {
      _isAnalyzing = false;
      _notifyAnalysisCompleted();
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  static Future<void> initialize() async {
    if (Hub.isInitialized && Hub.prefs != null) {
      final prefs = Hub.prefs!;

      // Load saved settings
      _isAutoAnalysisEnabled = prefs.getBool('auto_analysis_enabled') ?? false;
      _analysisIntervalMinutes = prefs.getInt('analysis_interval_minutes') ?? 1;

      // Validate interval range
      if (_analysisIntervalMinutes < 1 || _analysisIntervalMinutes > 60) {
        _analysisIntervalMinutes = 1;
      }

      Logger.info(
        'AutoAnalyzer initialized: enabled=$_isAutoAnalysisEnabled, interval=${_analysisIntervalMinutes}m',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------
  static void dispose() {
    stopAutoAnalysis();
    _onAnalysisStartedListeners.clear();
    _onAnalysisCompletedListeners.clear();
  }
}
