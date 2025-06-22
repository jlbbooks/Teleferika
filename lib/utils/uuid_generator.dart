// lib/utils/uuid_generator.dart
import 'package:uuid/uuid.dart';

// Create a single, private instance of Uuid for efficiency.
final _uuidInstance = Uuid();

/// Generates a v4 UUID string.
String generateUuid() {
  return _uuidInstance.v7();
}

// You can add other UUID versions here if needed in the future, e.g.:
// String generateUuidV1() {
//   return _uuidInstance.v1();
// }
