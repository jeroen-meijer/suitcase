part of 'cli.dart';

class PubspecNotFound implements Exception {}

/// Dart CLI
class DartCli {
  const DartCli();

  /// Determine whether dart is installed.
  Future<bool> isInstalled() async {
    try {
      await _Cmd.run(
        'dart',
        ['--version'],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Apply all fixes (`dart fix --apply`).
  ///
  /// If no [path] is provided, the current package dir is used.
  Future<void> applyFixes({
    Directory? path,
  }) async {
    final realPath = path ?? DirUtils.getPackageDir();

    final pubspec = File(p.join(realPath.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) throw PubspecNotFound();

    await _Cmd.run(
      'dart',
      ['fix', '--apply'],
      workingDirectory: realPath.path,
    );
  }

  /// Activate the packages at the given path.
  Future<void> activatePackage({
    required Directory directory,
  }) async {
    if (!directory.existsSync()) {
      throw Exception('Directory does not exist: ${directory.path}');
    }

    await _Cmd.run(
      'dart',
      ['pub', 'global', 'activate', '-s', 'path', directory.path],
    );
  }

  /// Runs the given Dart file.
  Future<void> runFile({
    required File file,
  }) async {
    if (!file.existsSync()) {
      throw Exception('File does not exist.');
    }
    if (!file.path.endsWith('.dart')) {
      throw Exception('File is not a Dart file.');
    }

    await _Cmd.run(
      'dart',
      ['run', file.path],
    );
  }
}
