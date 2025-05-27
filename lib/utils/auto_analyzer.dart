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
  static int _analysisIntervalSeconds = 10;
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
  static int get analysisIntervalSeconds => _analysisIntervalSeconds;
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
  static void startAutoAnalysis() {
    if (_isAutoAnalysisEnabled) {
      Logger.info('Auto analysis is already enabled.');
      return;
    }

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

  static void setAnalysisInterval(int seconds) {
    if (seconds < 5) {
      Logger.error('Analysis interval cannot be less than 5 seconds.');
      return;
    }

    _analysisIntervalSeconds = seconds;
    Logger.info('Analysis interval set to $_analysisIntervalSeconds seconds.');

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
      await Hub.prefs?.setInt('analysis_interval', _analysisIntervalSeconds);
    }
  }

  static void _scheduleNextAnalysis() {
    if (!_isAutoAnalysisEnabled) return;

    _nextAnalysisTime = DateTime.now().add(
      Duration(seconds: _analysisIntervalSeconds),
    );

    _analysisTimer = Timer(Duration(seconds: _analysisIntervalSeconds), () {
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

      // Perform the analysis
      Hub.analyze();

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
  // Cleanup
  // ---------------------------------------------------------------------------
  static void dispose() {
    stopAutoAnalysis();
    _onAnalysisStartedListeners.clear();
    _onAnalysisCompletedListeners.clear();
  }
}
