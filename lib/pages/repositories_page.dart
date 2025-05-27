import 'package:flutter/material.dart';
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
      body: Center(child: Text('Repositories will be displayed here.')),
    );
    // TODO: implement build
  }
}
