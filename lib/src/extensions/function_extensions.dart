import 'package:suitcase/src/utils/utils.dart';

extension FunctionExtensions<T> on T Function() {
  /// Ensures the given function returns successfully, and will throw an
  /// [Exception] with the given [message] if it does not.
  ///
  /// If a generic error type [E] is defined, this function will only catch
  /// errors of that type.
  ///
  /// If [showError] is `true` (set to `false` by default), the thrown error's
  /// message will also be printed to the console.
  T expect<E extends dynamic>(String? message, {bool showError = false}) {
    assert(
      message != null || showError,
      'If showError is false, a message must be provided.',
    );

    try {
      return this();
    } catch (e) {
      final didProvideErrorType = E == dynamic;
      if (didProvideErrorType && e is! E) {
        rethrow;
      }

      var errorMessage = message ?? '';
      if (showError) {
        errorMessage = '$errorMessage\n\n'
            '${ExceptionUtils.extractMessageFromError(e)}';
      }
      throw Exception(errorMessage.trim());
    }
  }
}
