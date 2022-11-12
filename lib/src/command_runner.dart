import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:suitcase/src/command_context.dart';
import 'package:suitcase/src/commands/commands.dart';
import 'package:suitcase/src/commands/dpa_command.dart';
import 'package:suitcase/src/commands/dpga_command.dart';
import 'package:suitcase/src/commands/fpga_command.dart';
import 'package:suitcase/src/utils/utils.dart';
import 'package:suitcase/src/version.dart';

const executableName = 'suitcase';
const packageName = 'suitcase';
const description = 'A collection of useful personal scripts and tools.';

const _nonLinkableCommands = ['help', upgradeCommandName];

/// {@template suitcase_command_runner}
/// A [CommandRunner] for the CLI.
///
/// ```
/// $ suitcase --version
/// ```
/// {@endtemplate}
class SuitcaseCommandRunner extends CommandRunner<int> {
  /// {@macro suitcase_command_runner}
  SuitcaseCommandRunner() : super(executableName, description) {
    // Ensure context exists.
    try {
      context;
    } catch (e) {
      rethrow;
    }

    // Add root options and flags
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        help: 'Noisy logging, including all shell commands executed.',
      );

    final commands = [
      GhoCommand(),
      UpgradeCommand(),
      DorfCommand(),
      ForfCommand(),
      DpgaCommand(),
      FpgaCommand(),
      DpaCommand(),
    ];

    // Add sub commands
    for (final command in commands) {
      addCommand(command);
    }
  }

  @override
  void printUsage() => context.logger.info(usage);

  Map<String, Command<int>> getLinkableCommands() {
    return Map.fromEntries([
      for (final entry in commands.entries)
        if (!_nonLinkableCommands.contains(entry.key)) entry
    ]);
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      if (topLevelResults['verbose'] == true) {
        context.logger.level = Level.verbose;
      }
      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      // On format errors, show the commands error message, root usage and
      // exit with an error code
      context.logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      context.logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    context.logger
      ..detail('Argument information:')
      ..detail('  Top level options:');
    for (final option in topLevelResults.options) {
      if (topLevelResults.wasParsed(option)) {
        context.logger.detail('  - $option: ${topLevelResults[option]}');
      }
    }
    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      context.logger
        ..detail('  Command: ${commandResult.name}')
        ..detail('    Command options:');
      for (final option in commandResult.options) {
        if (commandResult.wasParsed(option)) {
          context.logger.detail('    - $option: ${commandResult[option]}');
        }
      }
    }

    late final int? exitCode;
    if (topLevelResults['version'] == true) {
      context.logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      try {
        exitCode = await super.runCommand(topLevelResults);
      } catch (e) {
        context.logger.err(ExceptionUtils.extractMessageFromError(e));
        exitCode = ExitCode.software.code;
      }
    }

    return exitCode;
  }
}
