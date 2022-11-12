part of 'cli.dart';

/// Shell CLI
class ShellCli {
  const ShellCli();

  /// Runs the given command with the given args.
  Future<ProcessResult> run(
    String cmd,
    List<String>? args, {
    String? workingDirectory,
  }) {
    return _Cmd.run(
      'zsh',
      ['-ic', cmd, ...?args],
      workingDirectory: workingDirectory,
    );
  }
}
