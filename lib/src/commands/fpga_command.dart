import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:suitcase/src/command_context.dart';
import 'package:suitcase/src/extensions/extensions.dart';
import 'package:suitcase/src/utils/utils.dart';
import 'package:universal_io/io.dart';

const fpgaCommandName = 'fpga';

/// Command that runs `flutter pub get` in all Flutter projects in the
/// current directory and its recursive subdirectories.
class FpgaCommand extends Command<int> {
  FpgaCommand() {
    argParser
      ..addFlag(
        'use-fvm',
        abbr: 'v',
        defaultsTo: true,
        help: 'Use fvm to run the command.',
      )
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
        help: 'Show the output of pub get for each project.',
      );
  }

  @override
  String get name => fpgaCommandName;

  @override
  String get description => 'Runs `flutter pub get` in all Flutter projects in '
      'the current directory and its recursive subdirectories.';

  @override
  Future<int> run() async {
    final useFvm = argResults!['use-fvm'] as bool;
    final failFast = argResults!['fail-fast'] as bool;
    final showOutput = argResults!['show-output'] as bool;

    final command = useFvm ? 'fvm flutter pub get' : 'flutter pub get';

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

      final prog = context.logger
          .progress('Getting packages for $truncatedPathString...');
      try {
        final res = await context.shellCli
            .run(
              command,
              [],
              workingDirectory: dir.path,
            )
            .expect(
              'Failed to get packages for $truncatedPathString.',
              showError: true,
            );
        prog.complete();

        context.logger.detail('Output:\n---\n${res.stdout}\n---');

        if (showOutput) {
          context.logger.info(res.stdout.toString());
        }
      } catch (e) {
        prog.fail('Failed to get packages for $truncatedPathString.');
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
          'Failed get packages for ${failure.key.path}.\n\n'
          'Error:\n'
          '---\n'
          '${ExceptionUtils.extractMessageFromError(failure.value)}\n'
          '---',
        );
      } else {
        context.logger.err(
          'Failed to get package for ${failures.length} out of '
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
