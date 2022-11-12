import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:suitcase/src/command_context.dart';
import 'package:suitcase/src/extensions/extensions.dart';
import 'package:suitcase/src/utils/utils.dart';
import 'package:universal_io/io.dart';

const fuaCommandName = 'fua';

/// Command that sets the FVM version in all Flutter projects in the current
/// directory and its recursive subdirectories.
class FuaCommand extends Command<int> {
  FuaCommand() {
    argParser.addFlag(
      'ignore-errors',
      abbr: 'i',
      defaultsTo: true,
      help: 'Ignore any errors that may occur while setting the FVM version, '
          'in which case the command will continue running for other projects. '
          'Note that, regardless of this flag, the command will exit with a '
          'non-zero exit code if setting the FVM version fails for any '
          'project.',
    );
  }
  @override
  String get name => fuaCommandName;

  @override
  String get description => 'Sets the FVM version in all Flutter projects in '
      'the current directory and its recursive subdirectories.';

  @override
  Future<int> run() async {
    final ignoreErrors = argResults!['ignore-errors'] as bool;

    final version = (() => argResults!.rest.single)
        .expect<StateError>('Zero or more than one version argument provided.');

    final baseDir = Directory.current;

    final projectDiscoveryProgress = context.logger
        .progress('Finding Flutter projects in ${baseDir.path}...');
    final projects = DirUtils.getFlutterProjects(baseDir, recursive: true);
    projectDiscoveryProgress
        .complete('Found ${projects.length} Flutter project(s).');

    if (projects.isEmpty) {
      context.logger.info('No Flutter projects found.');
      return ExitCode.success.code;
    }

    final failures = <Directory, Object>{};

    for (final dir in projects) {
      Directory.current = dir.path;
      var truncatedPathString = dir.path.replaceFirst(baseDir.path, '').trim();
      if (truncatedPathString.isEmpty) {
        truncatedPathString = 'the current directory';
      }

      final prog =
          context.logger.progress('Running command in $truncatedPathString...');
      try {
        final res = await context.shellCli
            .run(
              'fvm use $version',
              [],
              workingDirectory: dir.path,
            )
            .expect(
              'Failed to run command in $truncatedPathString.',
              showError: true,
            );
        prog.complete();

        context.logger.detail('Output:\n---\n${res.stdout}\n---');
      } catch (e) {
        prog.fail('Failed to run command in $truncatedPathString.');
        if (ignoreErrors) {
          failures[dir] = e;
        } else {
          rethrow;
        }
      }
    }

    if (failures.isNotEmpty) {
      if (projects.length == 1) {
        final failure = failures.entries.single;

        context.logger.err(
          'Failed run command in ${failure.key.path}.\n\n'
          'Error:\n'
          '---\n'
          '${ExceptionUtils.extractMessageFromError(failure.value)}\n'
          '---',
        );
      } else {
        context.logger.err(
          'Failed to run command in ${failures.length} out of '
          '${projects.length} project(s).\n\n'
          'Hint: the first error encountered was:\n'
          '---\n'
          '${ExceptionUtils.extractMessageFromError(failures.values.first)}\n'
          '---',
        );
      }

      return 1;
    } else {
      return ExitCode.success.code;
    }
  }
}
