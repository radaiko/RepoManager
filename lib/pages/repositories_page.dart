import 'package:flutter/material.dart';
import 'package:repo_manager/utils/hub.dart';
import 'package:repo_manager/utils/logger.dart';
import 'package:repo_manager/utils/auto_analyzer.dart';

class RepositoriesPage extends StatefulWidget {
  const RepositoriesPage({super.key});

  @override
  State<RepositoriesPage> createState() => _RepositoriesPageState();
}

class _RepositoriesPageState extends State<RepositoriesPage> {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug("Building RepositoriesPage");
    return Scaffold(
      body: Column(
        children: [
          // Analysis status indicator - compact for desktop
          if (_isAnalyzing)
            Container(
              color: Colors.blue.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.2),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Analyzing repositories...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          // Repository list
          Expanded(
            child: Builder(
              builder: (context) {
                final folders = Hub.folders;

                if (folders.isEmpty) {
                  return const Center(
                    child: Text(
                      'No folders found. Please add some folders in settings.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                  itemCount: folders.fold<int>(
                    0,
                    (count, folder) => count + folder.repos.length,
                  ),
                  itemBuilder: (context, index) {
                    int currentIndex = 0;
                    for (final folder in folders) {
                      if (index < currentIndex + folder.repos.length) {
                        final repo = folder.repos[index - currentIndex];

                        // Determine the status icon and color based on main branch
                        Widget statusIcon = Icon(
                          Icons.source,
                          size: 16,
                          color: Colors.grey.shade600,
                        );
                        Color? titleColor;

                        if (repo.mainBranch.isRemoteAhead &&
                            repo.mainBranch.isLocalAhead) {
                          // Both remote and local are ahead - show up and down arrows
                          statusIcon = const Icon(
                            Icons.swap_vert,
                            color: Colors.orange,
                            size: 16,
                          );
                          titleColor = Colors.orange.shade700;
                        } else if (repo.mainBranch.isRemoteAhead) {
                          // Remote is ahead - show down arrow in red
                          statusIcon = const Icon(
                            Icons.arrow_downward,
                            color: Colors.red,
                            size: 16,
                          );
                          titleColor = Colors.red.shade700;
                        } else if (repo.mainBranch.isLocalAhead) {
                          // Local is ahead - show up arrow in green
                          statusIcon = const Icon(
                            Icons.arrow_upward,
                            color: Colors.green,
                            size: 16,
                          );
                          titleColor = Colors.green.shade700;
                        }

                        return ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(
                            horizontal: VisualDensity.minimumDensity,
                            vertical: VisualDensity.minimumDensity,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 0.0,
                          ),
                          minVerticalPadding: 0.0,
                          minLeadingWidth: 20,
                          title: Row(
                            children: [
                              Text(
                                repo.name,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  repo.path,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          leading: statusIcon,
                        );
                      }
                      currentIndex += folder.repos.length;
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
