import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:suitcase/src/command_context.dart';
import 'package:suitcase/src/extensions/extensions.dart';
import 'package:suitcase/src/utils/utils.dart';
import 'package:universal_io/io.dart';

const dpaCommandName = 'dpa';

/// Command that adds all given packages to a Dart project's dependencies.
///
/// In essence, this is a shortcut for running `dart pub add <package>` in a
/// project's root directory.
class DpaCommand extends Command<int> {
  DpaCommand() {
    argParser
      ..addFlag(
        'dev',
        abbr: 'd',
        help: 'Add the given packages as development dependencies.',
      )
      ..addFlag(
        'fail-fast',
        abbr: 'f',
        help: 'Exit the process immediately after a failure. If disabled, '
            'the command will continue running until all projects have been '
            'processed.',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'The path to the Dart project to which the packages should be '
            'added. If not specified, the current directory is used.',
      );
  }
  @override
  String get name => dpaCommandName;

  @override
  String get description => "Adds all given packages to a Dart project's "
      "dependencies. In essence, this is a shortcut for running 'dart pub add' "
      'for each package.';

  @override
  Future<int> run() async {
    final dev = argResults!['dev'] as bool;
    final failFast = argResults!['fail-fast'] as bool;
    final path = argResults!['path'] as String?;

    final packages = argResults!.rest;
    context.logger.detail('Received packages: "${packages.join(', ')}"');

    if (packages.isEmpty) {
      throw Exception(
        'No packages provided.\n\n'
        '$usage',
      );
    }

    final targetPackageDirPath = path ?? Directory.current.path;
    final targetPackageDir =
        DirUtils.getPackageDir(from: Directory(targetPackageDirPath));

    Directory.current = targetPackageDir;

    final failures = <String, Object>{};

    for (final packageName in packages) {
      final prog =
          context.logger.progress('Adding "$packageName" to dependencies...');
      try {
        final res = await context.shellCli
            .run(
              'dart pub add $packageName ${dev ? '--dev' : ''}',
              null,
              workingDirectory: targetPackageDir.path,
            )
            .expect(
              'Failed to add package "$packageName"',
              showError: true,
            );
        prog.complete();

        context.logger.detail('Output:\n---\n${res.stdout}\n---');
        if (res.stderr.toString().trim().isNotEmpty) {
          context.logger.err('Error:\n---\n${res.stderr}\n---');
        }
      } catch (e) {
        prog.fail('Failed to add package "$packageName"');
        context.logger.err('Error:\n---\n$e\n---');
        if (failFast) {
          rethrow;
        } else {
          failures[packageName] = e;
        }
      }
    }

    if (failures.isNotEmpty) {
      context.logger.err(
        'Failed to add ${failures.length} out of ${packages.length} '
        'package(s).',
      );

      return 1;
    } else {
      return ExitCode.success.code;
    }
  }
}
