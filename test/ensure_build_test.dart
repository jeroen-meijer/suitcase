@Tags(['version-verify'])
import 'package:build_verify/build_verify.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  late Logger logger;
  late Progress progress;

  setUp(() {
    logger = _MockLogger();
    progress = _MockProgress();
    when(() => logger.progress(any())).thenReturn(progress);
  });

  test('ensure_build', expectBuildClean);

  // test('ensure commands are generated', () async {
  //   await generateExecutables(logger: logger);

  //   final isClean = await Git.isClean(logger: logger);
  //   if (!isClean) {
  //     fail('Generated executables are not up to date.');
  //   }
  // });
}
