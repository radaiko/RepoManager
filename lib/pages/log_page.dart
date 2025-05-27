import 'package:flutter/material.dart';
import 'package:repo_manager/utils/logger.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final ScrollController _scrollController = ScrollController();
  LogLevel? _selectedLogLevel;

  void _onLogMessageAdded() {
    setState(() {
      // Only auto-scroll if no filter is active or if the new message matches the filter
      if (_selectedLogLevel == null) {
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
      }
    });
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.debugGit:
        return Colors.cyan;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.error:
        return Colors.red;
    }
  }

  List<LogMessage> _getFilteredMessages() {
    final allMessages = Logger.logMessages.toList();
    if (_selectedLogLevel == null) {
      print('Showing all messages: ${allMessages.length}');
      return allMessages;
    }
    final filtered = allMessages
        .where((message) => message.level == _selectedLogLevel)
        .toList();
    // Debug print to see what's happening
    print(
      'Total messages: ${allMessages.length}, Filtered for ${_selectedLogLevel}: ${filtered.length}',
    );
    return filtered;
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
    print('Building LogPage with filter: $_selectedLogLevel');
    final filteredMessages = _getFilteredMessages();
    print('Filtered messages count: ${filteredMessages.length}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Logs (${filteredMessages.length})'),
        actions: [
          // Add a separate "Clear Filter" button when a filter is active
          if (_selectedLogLevel != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear filter',
              onPressed: () {
                print('Clear filter button pressed');
                setState(() {
                  _selectedLogLevel = null;
                });
              },
            ),
          PopupMenuButton<LogLevel?>(
            icon: Icon(
              Icons.filter_list,
              color: _selectedLogLevel != null ? Colors.orange : null,
            ),
            tooltip: 'Filter by log level',
            onSelected: (LogLevel? value) {
              print('Filter selected: $value (was: $_selectedLogLevel)');
              setState(() {
                _selectedLogLevel = value;
                print('State updated: _selectedLogLevel = $_selectedLogLevel');
              });
              // Force a rebuild by calling build again
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {});
                }
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<LogLevel>(
                value: LogLevel.info,
                child: Row(
                  children: [
                    if (_selectedLogLevel == LogLevel.info)
                      const Icon(Icons.check, size: 16)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    const Text('Info'),
                  ],
                ),
              ),
              PopupMenuItem<LogLevel>(
                value: LogLevel.error,
                child: Row(
                  children: [
                    if (_selectedLogLevel == LogLevel.error)
                      const Icon(Icons.check, size: 16)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    const Text('Error'),
                  ],
                ),
              ),
              PopupMenuItem<LogLevel>(
                value: LogLevel.debug,
                child: Row(
                  children: [
                    if (_selectedLogLevel == LogLevel.debug)
                      const Icon(Icons.check, size: 16)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    const Text('Debug'),
                  ],
                ),
              ),
              PopupMenuItem<LogLevel>(
                value: LogLevel.debugGit,
                child: Row(
                  children: [
                    if (_selectedLogLevel == LogLevel.debugGit)
                      const Icon(Icons.check, size: 16)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    const Text('Debug Git'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: filteredMessages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedLogLevel == null
                        ? 'No log messages yet'
                        : 'No ${_selectedLogLevel.toString().split('.').last} messages',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total messages: ${Logger.logMessages.length}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              itemCount: filteredMessages.length,
              itemBuilder: (context, index) {
                final message = filteredMessages[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 1,
                    horizontal: 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timestamp column
                      Container(
                        width: 65,
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}:${message.timestamp.second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      // Log level column
                      Container(
                        width: 60,
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          message.level
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          style: TextStyle(
                            color: _getLogLevelColor(message.level),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      // Message and caller info
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(
                              context,
                            ).style.copyWith(fontSize: 13),
                            children: [
                              TextSpan(text: message.message),
                              if (message.caller.isNotEmpty)
                                TextSpan(
                                  text:
                                      ' [${message.caller} (${message.source}:${message.line})]',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
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
