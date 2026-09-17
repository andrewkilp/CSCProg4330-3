/// Safe user-facing failure; never expose raw database errors in the UI.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}

final class StorageException extends AppException {
  const StorageException(super.message);
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message);
}
