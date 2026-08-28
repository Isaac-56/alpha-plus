class DriverRegistration {
  DriverRegistration();

  static const String ridesService = 'rides';

  String serviceType = ridesService;

  String vehicleType = '';
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
      vehicleType.isNotEmpty &&
      make.isNotEmpty &&
      model.isNotEmpty &&
      color.isNotEmpty &&
      manufactureYear.length == 4 &&
      plateNumber.trim().length >= 4;

  bool get licenceComplete =>
      licenceCountry.isNotEmpty &&
      licenceFirstName.trim().isNotEmpty &&
      licenceLastName.trim().isNotEmpty &&
      licenceNumber.trim().isNotEmpty &&
      licenceIssueDate.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceType': serviceType,
      'vehicleType': vehicleType,
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

    return DriverRegistration()
      ..serviceType =
          values['serviceType'] as String? ?? DriverRegistration.ridesService
      ..vehicleType = values['vehicleType'] as String? ?? ''
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
