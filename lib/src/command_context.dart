import 'dart:async';

import 'package:mason_logger/mason_logger.dart';
import 'package:suitcase/src/cli/cli.dart';

class CommandContext {
  CommandContext({
    required this.logger,
    required this.dartCli,
    required this.gitCli,
    required this.shellCli,
  });

  factory CommandContext.fallback() {
    return CommandContext(
      logger: _defaultLogger,
      dartCli: _defaultDartCli,
      gitCli: _defaultGitCli,
      shellCli: _defaultShellCli,
    );
  }

  static final _defaultLogger = Logger();
  static const _defaultDartCli = DartCli();
  static const _defaultGitCli = GitCli();
  static const _defaultShellCli = ShellCli();

  final Logger logger;
  final DartCli dartCli;
  final GitCli gitCli;
  final ShellCli shellCli;
}

const _contextKey = #suitcase_command.logger;

T withContext<T>(CommandContext context, T Function() fn) {
  return runZoned(fn, zoneValues: {_contextKey: context});
}

CommandContext get context {
  final c = Zone.current[_contextKey] as CommandContext?;
  if (c == null) {
    throw StateError('No CommandContext found in current zone.');
  }
  return c;
}
