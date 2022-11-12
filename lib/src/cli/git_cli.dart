part of 'cli.dart';

/// {@template unreachable_git_dependency}
/// Thrown when `flutter packages get` or `flutter pub get`
/// encounters an unreachable git dependency.
/// {@endtemplate}
class UnreachableGitDependency implements Exception {
  /// {@macro unreachable_git_dependency}
  const UnreachableGitDependency({required this.remote});

  /// The associated git remote [Uri].
  final Uri remote;

  @override
  String toString() {
    return '''
$remote is unreachable.
Make sure the remote exists and you have the correct access rights.''';
  }
}

/// Git CLI
class GitCli {
  const GitCli();

  /// Determine whether the [remote] is reachable.
  Future<void> reachable(
    Uri remote, {
    required Logger logger,
  }) async {
    try {
      await _Cmd.run(
        'git',
        ['ls-remote', '$remote', '--exit-code'],
      );
    } catch (_) {
      throw UnreachableGitDependency(remote: remote);
    }
  }

  /// Checks whether the current git status is clean. Returns `true` if the
  /// current git status is clean, otherwise `false`.
  Future<bool> isClean({required Logger logger}) async {
    try {
      await _Cmd.run(
        'git',
        ['status', '--porcelain'],
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
