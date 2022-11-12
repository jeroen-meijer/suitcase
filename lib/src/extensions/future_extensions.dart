extension FutureExtensions<T> on Future<T> {
  /// Ensures this Future completes, and will throw an [Exception] with the
  /// given [message] if it does not.
  ///
  /// If [showError] is `true` (set to `false` by default), the thrown error's
  /// message will also be printed to the console.
  Future<T> expect(String message, {bool showError = false}) {
    return catchError((Object e, stackTrace) {
      var errorMessage = message;
      if (showError) {
        errorMessage = '$errorMessage\n\n$e';
      }
      throw Exception(errorMessage);
    });
  }
}
