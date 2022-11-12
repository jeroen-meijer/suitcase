class ExceptionUtils {
  /// Attempts to extract a message from the given error object [e].
  ///
  /// If no message can be extracted, returns the string representation of [e].
  static String extractMessageFromError(Object e) {
    try {
      // ignore: avoid_dynamic_calls
      return (e as dynamic).message as String;
    } catch (_) {
      return e.toString();
    }
  }
}
