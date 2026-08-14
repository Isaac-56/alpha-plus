class DriverRegistration {
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
}
