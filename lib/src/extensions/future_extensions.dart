import 'package:suitcase/src/utils/utils.dart';

extension FutureExtensions<T> on Future<T> {
  /// Ensures this Future completes, and will throw an [Exception] with the
  /// given [message] if it does not.
  ///
  /// If [showError] is `true` (set to `false` by default), the thrown error's
  /// message will also be printed to the console.
  Future<T> expect(String? message, {bool showError = false}) {
    assert(
      message != null || showError,
      'If showError is false, a message must be provided.',
    );

    return catchError((Object e, stackTrace) {
      var errorMessage = message ?? '';
      if (showError) {
        errorMessage = '$errorMessage\n\n'
            '${ExceptionUtils.extractMessageFromError(e)}';
      }
      throw Exception(errorMessage.trim());
    });
  }
}
