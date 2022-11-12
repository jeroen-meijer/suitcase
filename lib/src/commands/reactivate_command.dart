import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:suitcase/generate_executables.dart';
import 'package:suitcase/src/command_context.dart';
import 'package:suitcase/src/extensions/extensions.dart';
import 'package:suitcase/src/utils/utils.dart';

const upgradeCommandName = 'upgrade';

class UpgradeCommand extends Command<int> {
  UpgradeCommand() {
    argParser.addFlag(
      'remove-existing',
      abbr: 'r',
      defaultsTo: true,
      help: 'Remove existing executables before generating new ones.',
    );
  }

  @override
  String get name => upgradeCommandName;

  @override
  String get description => 'Upgrades suitcase by regenerating the executables '
      'and reactivating the package';

  @override
  Future<int> run() async {
    final removeExisting = argResults!['remove-existing'] as bool;

    final packageDir = DirUtils.getPackageDir();

    final firstActivationProg =
        context.logger.progress('Activating package (pass 1)...');
    await context.dartCli.activatePackage(directory: packageDir).expect(
          'Failed to activate package.',
          showError: true,
        );
    firstActivationProg.complete('Package activated.');

    await generateExecutables(
      removeExisting: removeExisting,
    ).expect('Failed to generate executables.', showError: true);

    final secondActivationProg =
        context.logger.progress('Activating package (pass 2)...');
    await context.dartCli.activatePackage(directory: packageDir).expect(
          'Failed to activate package.',
          showError: true,
        );
    secondActivationProg.complete('Package reactivated.');

    return ExitCode.success.code;
  }
}
