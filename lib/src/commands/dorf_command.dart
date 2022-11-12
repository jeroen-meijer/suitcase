import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:suitcase/src/command_context.dart';
import 'package:suitcase/src/extensions/extensions.dart';
import 'package:suitcase/src/utils/utils.dart';
import 'package:universal_io/io.dart';

const dorfCommandName = 'dorf';

/// Command that runs the given command in all Dart projects in the current
/// directory and its recursive subdirectories.
///
/// If `--ignore-errors` is `true` (the default), the command will continue
/// running even if a command fails for a given project.
class DorfCommand extends Command<int> {
  DorfCommand() {
    argParser
      ..addFlag(
        'ignore-errors',
        abbr: 'i',
        defaultsTo: true,
        help: 'Ignore any errors that may while running the given command, in '
            'which case the command will continue running for other projects. '
            'Note that, regardless of this flag, the command will exit with a '
            'non-zero exit code if the given command fails for any project.',
      )
      ..addFlag(
        'show-output',
        abbr: 'o',
        defaultsTo: true,
        help: 'Show the output of the given command for each project.',
      )
      ..addFlag(
        'ignore-flutter',
        abbr: 'f',
        defaultsTo: true,
        help: 'Ignore all Flutter projects (i.e., only run the given command '
            'for pure Dart projects).',
      );
  }
  @override
  String get name => dorfCommandName;

  @override
  String get description => 'Runs the given command in all Dart projects in '
      'the current directory and its recursive subdirectories.';

  @override
  Future<int> run() async {
    final ignoreErrors = argResults!['ignore-errors'] as bool;
    final showOutput = argResults!['show-output'] as bool;
    final ignoreFlutter = argResults!['ignore-flutter'] as bool;

    final command = argResults!.rest.join(' ');
    context.logger.detail('Received command: "$command"');

    if (command.isEmpty) {
      throw Exception(
        'No command provided.\n\n'
        '$usage',
      );
    }

    final baseDir = Directory.current;

    final projectDiscoveryProgress =
        context.logger.progress('Finding Dart projects in ${baseDir.path}...');
    final projects = DirUtils.getDartProjects(baseDir, recursive: true);
    if (ignoreFlutter) {
      projects.removeWhere(DirUtils.isFlutterProject);
    }
    projectDiscoveryProgress
        .complete('Found ${projects.length} Dart project(s).');

    if (projects.isEmpty) {
      context.logger.info('No Dart projects found.');
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
          '${projects.length} projects.\n\n'
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