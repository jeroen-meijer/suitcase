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
    final subDirs = [
      dir,
      ...dir.listSync(recursive: recursive).whereType<Directory>(),
    ];

    for (final subDir in subDirs) {
      final isInsideIgnoredDir =
          subDir.path.split('/').any(_ignoredPubspecDirectories.contains);

      if (!isInsideIgnoredDir) {
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
  /// file and this file contains a `flutter` key in the `dependencies` or
  /// `environment` section.
  /// See [isFlutterProject] for more details.
  ///
  /// Projects that live inside directories such as `.dart_tool` or `.fvm` are
  /// ignored.
  ///
  /// If [recursive] is `true` (the default), then the search will be recursive.
  static List<Directory> getFlutterProjects(
    Directory dir, {
    bool recursive = false,
  }) {
    final dartProjects = getDartProjects(dir, recursive: recursive);
    return [
      for (final project in dartProjects)
        if (isFlutterProject(project)) project,
    ];
  }

  /// Returns whether the current directory is a Flutter project.
  ///
  /// A folder is a considered Flutter project if it contains a `pubspec.yaml`
  /// file and this file contains a `flutter` key in the `dependencies` or
  /// `environment` section.
  static bool isFlutterProject(Directory dir) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    try {
      final pubspecContent = pubspec.readAsStringSync();
      final pubspecYaml = YamlEditor(pubspecContent);

      final environment = pubspecYaml.parseAt(['environment']);
      final dependencies = pubspecYaml.parseAt(['dependencies']);
      return environment is YamlMap && environment.containsKey('flutter') ||
          dependencies is YamlMap && dependencies.containsKey('flutter');
    } catch (_) {
      // Ignore.
    }

    return false;
  }
}
