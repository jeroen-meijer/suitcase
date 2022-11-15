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
      'fail-fast',
      abbr: 'f',
      help: 'Exit the process immediately after a failure. If disabled, '
          'the command will continue running until all projects have been '
          'processed.',
    );
  }
  @override
  String get name => fuaCommandName;

  @override
  String get description => 'Sets the FVM version in all Flutter projects in '
      'the current directory and its recursive subdirectories.';

  @override
  Future<int> run() async {
    final failFast = argResults!['fail-fast'] as bool;

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
        if (failFast) {
          rethrow;
        } else {
          failures[dir] = e;
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
