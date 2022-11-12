import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:suitcase/src/command_context.dart';
import 'package:suitcase/src/extensions/extensions.dart';
import 'package:universal_io/io.dart';

const ghoCommandName = 'gho';

/// Command that opens the current repository in a browser.
class GhoCommand extends Command<int> {
  GhoCommand() {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'The path to the repository to open. '
          'If not provided, the current working directory is used.',
    );
  }
  @override
  String get name => ghoCommandName;

  @override
  String get description => 'Open the current repository in a browser';

  @override
  Future<int> run() async {
    final workingDirectoryPath =
        argResults!['path'] as String? ?? Directory.current.path;

    final remoteUrlCmd = await context.shellCli
        .run(
          'git',
          ['config', '--get', 'remote.origin.url'],
          workingDirectory: workingDirectoryPath,
        )
        .expect(
          'Failed to get remote origin url.\n'
          'Ensure you are running this command in a git repository or that '
          'the provided path is a git repository.',
        );

    final remoteUrl = remoteUrlCmd.stdout.toString().trim();

    await context.shellCli.run(
      'open',
      [remoteUrl],
    ).expect(
      'Failed to open remote url in browser.',
      showError: true,
    );

    return ExitCode.success.code;
  }
}
