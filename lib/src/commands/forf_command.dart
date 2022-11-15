import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:suitcase/src/command_context.dart';
import 'package:suitcase/src/extensions/extensions.dart';
import 'package:suitcase/src/utils/utils.dart';
import 'package:universal_io/io.dart';

const forfCommandName = 'forf';

/// Command that runs the given command in all Flutter projects in the current
/// directory and its recursive subdirectories.
class ForfCommand extends Command<int> {
  ForfCommand() {
    argParser
      ..addFlag(
        'fail-fast',
        abbr: 'f',
        help: 'Exit the process immediately after a failure. If disabled, '
            'the command will continue running until all projects have been '
            'processed.',
      )
      ..addFlag(
        'show-output',
        abbr: 'o',
        defaultsTo: true,
        help: 'Show the output of the given command for each project.',
      )
      ..addFlag(
        'ignore-pure-dart',
        abbr: 'p',
        defaultsTo: true,
        help: 'Ignore any projects that are pure Dart projects.',
      );
  }
  @override
  String get name => forfCommandName;

  @override
  String get description => 'Runs the given command in all Flutter projects in '
      'the current directory and its recursive subdirectories.';

  @override
  Future<int> run() async {
    final failFast = argResults!['fail-fast'] as bool;
    final showOutput = argResults!['show-output'] as bool;

    final command = argResults!.rest.join(' ');
    context.logger.detail('Received command: "$command"');

    if (command.isEmpty) {
      throw Exception(
        'No command provided.\n\n'
        '$usage',
      );
    }

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
              command,
              [],
              workingDirectory: dir.path,
            )
            .expect(
              'Failed to run command in $truncatedPathString.',
              showError: true,
            );
        prog.complete();

        context.logger.detail('Output:\n---\n${res.stdout}\n---');

        if (showOutput) {
          context.logger.info(res.stdout.toString());
        }
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
