class DriverRegistration {
  DriverRegistration();

  static const String ridesService = 'rides';

  static const List<String> supportedVehicleTypes = <String>[
    'Sedan',
    'Hatchback',
    'SUV / 4x4',
    'Minivan / MPV',
    'Pickup',
    'Boda boda (motorcycle)',
    'Bajaj / Tuk-tuk (three-wheeler)',
    'Scooter',
  ];

  static const List<String> adminVehicleClasses = <String>[
    'standard',
    'comfort',
    'ev',
    'premium',
    'corporate',
  ];

  String serviceType = ridesService;

  /// Physical vehicle body selected by the driver during registration.
  String vehicleType = '';

  /// Alpha service class assigned by an administrator for regular cars.
  ///
  /// Boda, three-wheeler and scooter registrations derive their class from
  /// [vehicleType] and never rely on a driver-selected commercial tier.
  String vehicleClass = '';

  String make = '';
  String model = '';
  String color = '';
  String manufactureYear = '';
  String plateNumber = '';

  String licenceCountry = 'South Sudan';
  String licenceFirstName = '';
  String licenceLastName = '';
  String licenceNumber = '';
  String licenceIssueDate = '';

  bool get serviceComplete => serviceType.trim().isNotEmpty;

  bool get vehicleComplete =>
      vehicleType.trim().isNotEmpty &&
      make.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      color.trim().isNotEmpty &&
      manufactureYear.length == 4 &&
      plateNumber.trim().length >= 4;

  bool get licenceComplete =>
      licenceCountry.isNotEmpty &&
      licenceFirstName.trim().isNotEmpty &&
      licenceLastName.trim().isNotEmpty &&
      licenceNumber.trim().isNotEmpty &&
      licenceIssueDate.trim().isNotEmpty;

  String get fixedVehicleClass {
    final String normalized = vehicleType.trim().toLowerCase();
    if (normalized.contains('rickshaw') ||
        normalized.contains('tuk') ||
        normalized.contains('three') ||
        normalized.contains('bajaj')) {
      return 'rickshaw';
    }
    if (normalized.contains('boda') ||
        normalized.contains('motorcycle') ||
        normalized.contains('scooter')) {
      return 'boda';
    }
    return '';
  }

  bool get requiresAdminVehicleClass =>
      vehicleType.trim().isNotEmpty && fixedVehicleClass.isEmpty;

  String get effectiveVehicleClass {
    final String fixed = fixedVehicleClass;
    if (fixed.isNotEmpty) return fixed;
    return normalizeVehicleClass(vehicleClass);
  }

  String get vehicleClassLabel {
    return switch (effectiveVehicleClass) {
      'boda' => 'Boda',
      'rickshaw' => 'Rickshaw',
      'standard' => 'Standard',
      'comfort' => 'Comfort',
      'ev' => 'Electric',
      'premium' => 'Premium',
      'corporate' => 'Corporate',
      _ => 'Assigned after Alpha review',
    };
  }

  static String normalizeVehicleClass(String value) {
    final String normalized = value.trim().toLowerCase();
    return adminVehicleClasses.contains(normalized) ? normalized : '';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceType': serviceType,
      'vehicleType': vehicleType,
      'vehicleClass': vehicleClass,
      'make': make,
      'model': model,
      'color': color,
      'manufactureYear': manufactureYear,
      'plateNumber': plateNumber,
      'licenceCountry': licenceCountry,
      'licenceFirstName': licenceFirstName,
      'licenceLastName': licenceLastName,
      'licenceNumber': licenceNumber,
      'licenceIssueDate': licenceIssueDate,
    };
  }

  factory DriverRegistration.fromMap(Map<String, dynamic>? data) {
    final Map<String, dynamic> values = data ?? <String, dynamic>{};
    final String storedVehicleType = values['vehicleType'] as String? ?? '';
    final String storedVehicleClass = values['vehicleClass'] as String? ?? '';

    // Profiles created before vehicle classes existed treated "Car" as
    // Standard. Preserve that live behavior until an administrator reclassifies
    // the vehicle. New registrations always persist an explicit blank class.
    final String compatibleVehicleClass =
        !values.containsKey('vehicleClass') &&
                storedVehicleType.trim().toLowerCase() == 'car'
            ? 'standard'
            : DriverRegistration.normalizeVehicleClass(storedVehicleClass);

    return DriverRegistration()
      ..serviceType =
          values['serviceType'] as String? ?? DriverRegistration.ridesService
      ..vehicleType = storedVehicleType
      ..vehicleClass = compatibleVehicleClass
      ..make = values['make'] as String? ?? ''
      ..model = values['model'] as String? ?? ''
      ..color = values['color'] as String? ?? ''
      ..manufactureYear = values['manufactureYear'] as String? ?? ''
      ..plateNumber = values['plateNumber'] as String? ?? ''
      ..licenceCountry = values['licenceCountry'] as String? ?? 'South Sudan'
      ..licenceFirstName = values['licenceFirstName'] as String? ?? ''
      ..licenceLastName = values['licenceLastName'] as String? ?? ''
      ..licenceNumber = values['licenceNumber'] as String? ?? ''
      ..licenceIssueDate = values['licenceIssueDate'] as String? ?? '';
  }
}
