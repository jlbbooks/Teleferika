// lib/utils/uuid_generator.dart
import 'package:uuid/uuid.dart';

// Create a single, private instance of Uuid for efficiency.
// You could also make UuidGenerator a class if you prefer,
// but a top-level function is often sufficient.
final _uuidInstance = Uuid();

/// Generates a v4 UUID string.
String generateUuidV4() {
  return _uuidInstance.v4();
}

// You can add other UUID versions here if needed in the future, e.g.:
// String generateUuidV1() {
//   return _uuidInstance.v1();
// }
