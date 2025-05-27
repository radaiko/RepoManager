import 'package:flutter/material.dart';
import 'package:repo_manager/utils/hub.dart';
import 'package:repo_manager/utils/logger.dart';

class RepositoriesPage extends StatefulWidget {
  const RepositoriesPage({super.key});

  @override
  State<RepositoriesPage> createState() => _RepositoriesPageState();
}

class _RepositoriesPageState extends State<RepositoriesPage> {
  @override
  Widget build(BuildContext context) {
    Logger.debug("Building RepositoriesPage");
    return Scaffold(
      body: Builder(
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
                  Widget statusIcon = const Icon(Icons.source);
                  Color? titleColor;

                  if (repo.mainBranch.isRemoteAhead) {
                    // Remote is ahead - show down arrow in red
                    statusIcon = const Icon(
                      Icons.arrow_downward,
                      color: Colors.red,
                    );
                    titleColor = Colors.red.shade700;
                  } else if (repo.mainBranch.isLocalAhead) {
                    // Local is ahead - show up arrow in green
                    statusIcon = const Icon(
                      Icons.arrow_upward,
                      color: Colors.green,
                    );
                    titleColor = Colors.green.shade700;
                  }

                  return ListTile(
                    title: Text(
                      repo.name,
                      style: titleColor != null
                          ? TextStyle(color: titleColor)
                          : null,
                    ),
                    subtitle: Text(repo.path),
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
    );
  }
}
