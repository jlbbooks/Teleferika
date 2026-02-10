// lib/utils/uuid_generator.dart
import 'package:uuid/uuid.dart';

// Create a single, private instance of Uuid for efficiency.
final _uuidInstance = const Uuid();

/// Generates a v7 UUID string.
///
/// UUID v7 is time-ordered and includes random data for uniqueness,
/// making it suitable for database keys where temporal locality is beneficial.
String generateUuid() {
  // Renamed for clarity, if you might add other versions
  // The v7() method without arguments will use the current time
  // and internally generate the required random bits.
  return _uuidInstance.v7();
}

/*
// If you need more control over the timestamp or random data (e.g., for testing or specific sequences):
String generateUuidV7WithConfig({DateTime? customTime, List<int>? randomBytes}) {
  final timestamp = customTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

  // v7 needs 74 bits of random data (rand_a and rand_b).
  // The Uuid package's v7 method with config expects 10 bytes (80 bits) for the random part.
  // It will take the necessary bits from this.
  // If randomBytes is null or not 10 bytes, Uuid.v7() might throw or misbehave with custom config.
  // It's often safer to let Uuid.v7() generate its own random bytes unless you have a specific need.

  List<int> effectiveRandomBytes;
  if (randomBytes != null && randomBytes.length == 10) {
    effectiveRandomBytes = randomBytes;
  } else {
    // Generate 10 random bytes if not provided or if the length is incorrect.
    // Note: Uuid.v7() without config handles this internally and more robustly.
    // This explicit generation is more for illustration if precise control is needed.
    var generator = UuidUtil(); // UuidUtil provides random byte generation
    effectiveRandomBytes = generator.generateNumericRandomBytes(10);
  }

  return _uuidInstance.v7(
    config: V7Options(
      timestamp,
      effectiveRandomBytes,
    )
  );
}
*/

// For most common use cases, the simpler version is preferred:
// String generateUuid() {
//   return _uuidInstance.v7();
// }
