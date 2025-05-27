import 'dart:convert';
import 'dart:io';

import 'package:repo_manager/utils/extensions.dart';
import 'package:repo_manager/utils/logger.dart';

class Git {
  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------
  /// Returns the current active branch
  static Future<String> getCurrentBranch(String workingDirectory) async {
    return _run('rev-parse --abbrev-ref HEAD', workingDirectory);
  }

  /// Returns a list of all branches in the repository
  static Future<List<String>> getAllBranches(String workingDirectory) async {
    var output = await _run(
      'branch --list --format=%(refname:short)',
      workingDirectory,
    );
    return output
        .lineSplit()
        .map((line) => line.replaceAll(RegExp(r"['*\s]"), '').trim())
        .toList();
  }

  /// Fetch all branches and updates from the remote repository
  static Future<void> fetchAll(String workingDirectory) async {
    await _run('fetch --all', workingDirectory);
  }

  static Future<List<String>> getUnstagedFilePaths(
    String workingDirectory,
  ) async {
    var output = await _run('diff --name-only', workingDirectory);
    return output.lineSplit();
  }

  static Future<List<String>> getStagedFilePaths(
    String workingDirectory,
  ) async {
    var output = await _run('diff --cached --name-only', workingDirectory);
    return output.lineSplit();
  }

  static Future<List<String>> getUntrackedFiles(String workingDirectory) async {
    var output = await _run(
      'ls-files --others --exclude-standard',
      workingDirectory,
    );
    return output.lineSplit();
  }

  static Future<int> getCommitsToPush(String workingDirectory) async {
    var output = await _run('rev-list --count @{u}..HEAD', workingDirectory);
    return int.tryParse(output) ?? 0;
  }

  static Future<int> getCommitsToPull(String workingDirectory) async {
    var output = await _run('rev-list --count HEAD..@{u}', workingDirectory);
    return int.tryParse(output) ?? 0;
  }

  static Future<String> getRemoteUrl(String workingDirectory) async {
    return _run('config --get remote.origin.url', workingDirectory);
  }

  static Future<String> getDiff(
    String workingDirectory, {
    String diffBranch = "HEAD",
  }) async {
    return _run('diff $diffBranch', workingDirectory);
  }

  static Future<List<String>> getDiffArray(
    String workingDirectory, {
    String diffBranch = "HEAD",
  }) async {
    var output = await getDiff(workingDirectory, diffBranch: diffBranch);
    return output.lineSplit();
  }

  static Future<bool> checkIfHasRemote(
    String workingDirectory,
    String branchName,
  ) async {
    var output = await _run(
      'ls-remote --heads origin $branchName',
      workingDirectory,
    );
    return output.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------------
  static Future<String> _run(String command, String workingDirectory) async {
    var sw = Stopwatch();
    sw.start();

    var process = await Process.start(
      'git',
      command.split(' '),
      workingDirectory: workingDirectory,
      runInShell: false,
    );
    var output = await process.stdout.transform(utf8.decoder).join();
    var error = await process.stderr.transform(utf8.decoder).join();
    var exitCode = await process.exitCode;
    sw.stop();
    Logger.debug("git $command -- took ${sw.elapsedHumanReadable} ms");
    if (exitCode == 0) {
      return output.trimRight();
    }
    Logger.error("Git command failed with exit code $exitCode: $error");
    return "";
  }
}
