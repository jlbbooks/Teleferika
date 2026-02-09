// projects/cable_equipment_presets.dart

/// Seed-only record for cable types. Used by DB migration/creation to populate
/// the cable_types table. Fixed UUIDs ensure deterministic IDs; seed runs only
/// when the table is empty.
typedef CableTypeSeedRecord = ({
  String id,
  String name,
  double diameterMm,
  double weightPerMeterKg,
  double breakingLoadKn,
  double? elasticModulusGPa,
  int sortOrder,
});

/// Data needed per cable type for sag, clearance, and payload/span calculations.
///
/// Typical use:
/// - **Sag / clearance:** Parabolic sag ≈ (w × (L/2)²) / (2×T) — needs
///   [weightPerMeterKg] and working tension (or derive from [breakingLoadKn]
///   and safety factor).
/// - **Payload vs span:** Max tension limited by [breakingLoadKn]; span and
///   payload depend on [weightPerMeterKg], slope, and safety factor.
/// - **Diameter** is stored in cable_types; fetch from DB for calculations.
///
/// References: FUNCTIONS_FOR_COMPANIES_README (§1 Sag, Payload vs span),
/// Teufelberger F20, engineeringtoolbox cable loads, PLOS ONE standing skyline.
class CableTypeCalculationData {
  const CableTypeCalculationData({
    required this.diameterMm,
    required this.weightPerMeterKg,
    required this.breakingLoadKn,
    this.elasticModulusGPa,
  });

  /// Nominal rope diameter (mm).
  final double diameterMm;

  /// Mass per unit length (kg/m). Drives sag under self-weight.
  final double weightPerMeterKg;

  /// Minimum breaking load (kN). Used with a safety factor for max working tension.
  final double breakingLoadKn;

  /// Elastic modulus (GPa), if known. Improves sag accuracy under load.
  final double? elasticModulusGPa;
}

/// Built-in cable type seed data for DB initialization.
///
/// Based on common practice in Italy and European forestry:
/// - **Fune portante** (support/skyline): typically 20–22 mm, 850–1000 m
/// - **Fune traente** (haul/mainline): typically 11–12 mm
/// - **Skyline** diameters 12–20 mm align with Teufelberger F20 and similar
///   forestry ropes used in Alpine/long-distance systems
///
/// Used only for seeding cable_types; project details get data from the DB.
const List<CableTypeSeedRecord> cableEquipmentTypeSeedData = [
  (id: '018a1234-0000-7000-8000-000000000001', name: 'Fune portante 20 mm', diameterMm: 20, weightPerMeterKg: 1.4, breakingLoadKn: 320, elasticModulusGPa: null, sortOrder: 0),
  (id: '018a1234-0000-7000-8000-000000000002', name: 'Fune portante 22 mm', diameterMm: 22, weightPerMeterKg: 1.7, breakingLoadKn: 380, elasticModulusGPa: null, sortOrder: 1),
  (id: '018a1234-0000-7000-8000-000000000003', name: 'Fune traente 11 mm', diameterMm: 11, weightPerMeterKg: 0.42, breakingLoadKn: 120, elasticModulusGPa: null, sortOrder: 2),
  (id: '018a1234-0000-7000-8000-000000000004', name: 'Fune traente 12 mm', diameterMm: 12, weightPerMeterKg: 0.5, breakingLoadKn: 150, elasticModulusGPa: null, sortOrder: 3),
  (id: '018a1234-0000-7000-8000-000000000005', name: 'Skyline 12 mm', diameterMm: 12, weightPerMeterKg: 0.73, breakingLoadKn: 152.7, elasticModulusGPa: null, sortOrder: 4),
  (id: '018a1234-0000-7000-8000-000000000006', name: 'Skyline 14 mm', diameterMm: 14, weightPerMeterKg: 0.96, breakingLoadKn: 177, elasticModulusGPa: null, sortOrder: 5),
  (id: '018a1234-0000-7000-8000-000000000007', name: 'Skyline 16 mm', diameterMm: 16, weightPerMeterKg: 1.23, breakingLoadKn: 239, elasticModulusGPa: null, sortOrder: 6),
  (id: '018a1234-0000-7000-8000-000000000008', name: 'Skyline 20 mm', diameterMm: 20, weightPerMeterKg: 1.98, breakingLoadKn: 356, elasticModulusGPa: null, sortOrder: 7),
  (id: '018a1234-0000-7000-8000-000000000009', name: 'Mainline 12 mm', diameterMm: 12, weightPerMeterKg: 0.73, breakingLoadKn: 152.7, elasticModulusGPa: null, sortOrder: 8),
  (id: '018a1234-0000-7000-8000-00000000000a', name: 'Mainline 14 mm', diameterMm: 14, weightPerMeterKg: 0.96, breakingLoadKn: 177, elasticModulusGPa: null, sortOrder: 9),
];
