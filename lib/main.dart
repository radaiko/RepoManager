import 'package:flutter/material.dart';
import 'package:repo_manager/pages/log_page.dart';
import 'package:repo_manager/pages/repositories_page.dart';
import 'package:repo_manager/utils/hub.dart';
import 'package:repo_manager/utils/auto_analyzer.dart';
import 'utils/logger.dart';
import 'utils/common.dart';
import 'pages/about_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hub.initialize();
  // Setup logger
  final prefs = Hub.prefs;
  Logger.logToFile = prefs?.getBool('log_to_file') ?? true;
  Logger.logToConsole = prefs?.getBool('log_to_console') ?? false;
  final levelString = prefs?.getString('log_level') ?? LogLevel.info.name;
  Logger.logLevel = LogLevel.values.firstWhere(
    (level) => level.name == levelString,
    orElse: () => LogLevel.info,
  );
  Logger.info("Starting Repo Manager");
  Logger.info("LogFilePath: ${await Logger.logFilePath}");
  Logger.info("LogLevel: ${Logger.logLevel}");
  Logger.info("LogToFile: ${Logger.logToFile}");
  Logger.info("LogToConsole: ${Logger.logToConsole}");
  Logger.info("Current Device: ${Common.getCurrentDevice()}");

  // Load auto analysis settings and start if enabled
  final autoAnalysisEnabled = prefs?.getBool('auto_analysis_enabled') ?? true;
  final analysisInterval = prefs?.getInt('analysis_interval') ?? 10;

  if (analysisInterval >= 5) {
    AutoAnalyzer.setAnalysisInterval(analysisInterval);
  }

  if (autoAnalysisEnabled) {
    AutoAnalyzer.startAutoAnalysis();
    Logger.info("Auto analyzer started (interval: ${analysisInterval}s)");
  } else {
    Logger.info("Auto analyzer disabled in settings");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Repo Manager',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          // primary: Colors.blue,
          onPrimary: Colors.white,
          // secondary: Colors.blueAccent,
          onSecondary: Colors.white,
          surface: Colors.grey.shade50,
          onSurface: Colors.black87,
          // inversePrimary: Colors.blue.shade100,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          // primary: Colors.blue.shade700,
          onPrimary: Colors.white,
          // secondary: Colors.blueAccent.shade200,
          onSecondary: Colors.black,
          surface: Colors.grey.shade900,
          onSurface: Colors.white70,
          // inversePrimary: Colors.blue.shade800,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Repositories'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    AutoAnalyzer.addOnAnalysisStartedListener(_onAnalysisStarted);
    AutoAnalyzer.addOnAnalysisCompletedListener(_onAnalysisCompleted);
  }

  @override
  void dispose() {
    AutoAnalyzer.removeOnAnalysisStartedListener(_onAnalysisStarted);
    AutoAnalyzer.removeOnAnalysisCompletedListener(_onAnalysisCompleted);
    super.dispose();
  }

  void _onAnalysisStarted() {
    if (mounted) {
      setState(() {
        _isAnalyzing = true;
      });
    }
  }

  void _onAnalysisCompleted() {
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
      });

      // Show a brief notification when analysis completes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text('Repository analysis completed'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          width: 300,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.title),
            if (_isAnalyzing) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Analyzing...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              AutoAnalyzer.performManualAnalysis();
            },
            tooltip: 'Analyze Now',
          ),
        ],
      ),
      body: const RepositoriesPage(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AutoAnalyzer.performManualAnalysis();
        },
        tooltip: 'Analyze Repositories',
        child: const Icon(Icons.analytics),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Logs'),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LogPage()),
                );
              },
            ),
            ListTile(
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
