import 'package:path/path.dart' as p;
import 'package:suitcase/src/command_runner.dart';
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

class DirUtils {
  static const _ignoredPubspecDirectories = {
    'ios',
    'android',
    'windows',
    'linux',
    'macos',
    '.symlinks',
    '.plugin_symlinks',
    '.dart_tool',
    'build',
    '.fvm',
  };

  static Directory getPackageDir({Directory? from}) {
    final path = from != null ? from.path : Platform.script.toFilePath();

    var packageDir = Directory(path);
    while (packageDir.path.split(Platform.pathSeparator).last != packageName ||
        packageDir.path.contains('.dart_tool')) {
      packageDir = packageDir.parent;

      final isAtRoot = packageDir.parent == packageDir;
      if (isAtRoot) {
        throw Exception(
          'Could not find package directory for $packageName. '
          'Expected to find a directory named $packageName in the path: $path',
        );
      }
    }

    return packageDir;
  }

  /// Returns a list of directories containing Dart projects.
  ///
  /// A folder is a considered Dart project if it contains a `pubspec.yaml`
  /// file.
  ///
  /// Projects that live inside directories such as `.dart_tool` or `.fvm` are
  /// ignored.
  ///
  /// If [recursive] is `true` (the default), then the search will be recursive.
  static List<Directory> getDartProjects(
    Directory dir, {
    bool recursive = false,
  }) {
    final projects = <Directory>[];
    final subDirs = dir.listSync(recursive: recursive);

    for (final subDir in subDirs) {
      final isInsideIgnoredDir =
          subDir.path.split('/').any(_ignoredPubspecDirectories.contains);

      if (subDir is Directory && !isInsideIgnoredDir) {
        final pubspec = File(p.join(subDir.path, 'pubspec.yaml'));
        if (pubspec.existsSync()) {
          projects.add(subDir);
        }
      }
    }
    return projects;
  }

  /// Returns a list of directories containing Flutter projects.
  ///
  /// A folder is a considered Flutter project if it contains a `pubspec.yaml`
  /// file and this file contains a `flutter` key in the `environment` section.
  ///
  /// Projects that live inside directories such as `.dart_tool` or `.fvm` are
  /// ignored.
  ///
  /// If [recursive] is `true` (the default), then the search will be recursive.
  static List<Directory> getFlutterProjects(
    Directory dir, {
    bool recursive = false,
  }) {
    final projects = <Directory>[];
    final dartProjects = getDartProjects(dir, recursive: recursive);

    for (final dartProject in dartProjects) {
      final pubspec = File(p.join(dartProject.path, 'pubspec.yaml'));
      try {
        final pubspecContent = pubspec.readAsStringSync();
        final pubspecYaml = YamlEditor(pubspecContent);

        final environment = pubspecYaml.parseAt(['environment']);
        if (environment is YamlMap && environment.containsKey('flutter')) {
          projects.add(dartProject);
        }
      } catch (_) {
        // Ignore.
      }
    }

    return projects;
  }
}
