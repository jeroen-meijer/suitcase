import 'package:suitcase/src/command_context.dart';
import 'package:suitcase/src/command_runner.dart';
import 'package:universal_io/io.dart';

Future<void> runCommandRunner(
  List<String> args, {
  String? prefixedCommand,
}) async {
  await _flushThenExit(
    await withContext(
      CommandContext.fallback(),
      () {
        ProcessSignal.sigint.watch().listen((signal) {
          onUserExit();
        });
        return SuitcaseCommandRunner().run([
          if (prefixedCommand != null) prefixedCommand,
          ...args,
        ]);
      },
    ),
  );
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from proceeding
/// after you've decided to exit.
Future<void> _flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then<void>((_) => exit(status));
}

/// Called when the user cancels any operation using Ctrl+C.
void onUserExit() {
  context.logger
    ..write('\n\n')
    ..warn('User cancelled operation. Exiting...');
  exit(-2);
}
