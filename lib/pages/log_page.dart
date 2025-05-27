import 'package:flutter/material.dart';
import 'package:repo_manager/utils/log_level.dart';
import 'package:repo_manager/utils/logger.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final ScrollController _scrollController = ScrollController();

  void _onLogMessageAdded() {
    setState(() {
      // Schedule scroll to bottom after the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.error:
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  void initState() {
    super.initState();
    Logger.addOnLogMessageAddedListener(_onLogMessageAdded);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Logger.removeOnLogMessageAddedListener(_onLogMessageAdded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug("Building LogPage");
    return Scaffold(
      appBar: AppBar(title: const Text('Logs')),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: Logger.logMessages.length,
        itemBuilder: (context, index) {
          final message = Logger.logMessages.elementAt(index);
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    message.level.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: _getLogLevelColor(message.level),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.message),
                      if (message.caller.isNotEmpty)
                        Text(
                          'Caller: ${message.caller} (${message.source}:${message.line})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
