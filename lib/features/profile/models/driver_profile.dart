import '../../onboarding/models/driver_registration.dart';

class DriverProfile {
  const DriverProfile({
    required this.uid,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.onboardingCompleted,
    required this.reviewStatus,
    required this.registration,
  });

  final String uid;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final bool onboardingCompleted;
  final String reviewStatus;
  final DriverRegistration registration;

  String get fullName => '$firstName $lastName'.trim();

  bool get hasIdentity =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  factory DriverProfile.fromMap({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return DriverProfile(
      uid: uid,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      reviewStatus: data['reviewStatus'] as String? ?? 'draft',
      registration: DriverRegistration.fromMap(
        data['registration'] as Map<String, dynamic>?,
      ),
    );
  }
}
