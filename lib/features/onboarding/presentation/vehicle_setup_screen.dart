import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../models/driver_registration.dart';
import 'licence_information_screen.dart';
import 'registration_option_screen.dart';

class VehicleSetupScreen extends StatefulWidget {
  const VehicleSetupScreen({required this.driverName, super.key});

  final String driverName;

  @override
  State<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends State<VehicleSetupScreen> {
  final DriverRegistration _registration = DriverRegistration();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  static const List<String> _vehicleTypes = <String>[
    'Car',
    'Boda',
    'Rickshaw',
  ];
  static const List<String> _makes = <String>[
    'Toyota',
    'Nissan',
    'Honda',
    'Hyundai',
    'Kia',
    'Suzuki',
    'Bajaj',
    'TVS',
    'Other',
  ];
  static const List<String> _models = <String>[
    'Corolla',
    'Vitz',
    'Yaris',
    'Premio',
    'Noah',
    'Probox',
    'Sunny',
    'Tucson',
    'Sportage',
    'Boxer',
    'RE4S',
    'Other',
  ];
  static const Map<String, Color> _colors = <String, Color>{
    'White': Color(0xFFF7F7F4),
    'Black': Color(0xFF171917),
    'Silver': Color(0xFFB9BDB9),
    'Gray': Color(0xFF777B77),
    'Blue': Color(0xFF287BC1),
    'Red': Color(0xFFE44742),
    'Green': Color(0xFF2E9A55),
    'Brown': Color(0xFF865634),
    'Beige': Color(0xFFDCCDA0),
    'Yellow': Color(0xFFFFD836),
    'Other': Color(0xFFE9ECE9),
  };

  @override
  void dispose() {
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _pick({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
    String? selected,
    Map<String, Color> colors = const <String, Color>{},
  }) async {
    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => RegistrationOptionScreen(
          title: title,
          options: options,
          selected: selected,
          colors: colors,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => onSelected(result));
    }
  }

  void _continue() {
    _registration
      ..manufactureYear = _yearController.text
      ..plateNumber = _plateController.text.trim().toUpperCase();
    if (!_registration.vehicleComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete every vehicle detail first.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LicenceInformationScreen(
          driverName: widget.driverName,
          registration: _registration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Enter your vehicle details',
      subtitle: 'Tell us about the vehicle you own or rent for trips.',
      bottom: ElevatedButton(
        onPressed: _continue,
        child: const Text('Continue'),
      ),
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: <Widget>[
            _VehicleIllustration(type: _registration.vehicleType),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: <Widget>[
            _PickerRow(
              label: 'Type of vehicle',
              value: _registration.vehicleType,
              icon: Icons.local_taxi_rounded,
              onTap: () => _pick(
                title: 'Vehicle type',
                options: _vehicleTypes,
                selected: _registration.vehicleType,
                onSelected: (String value) {
                  _registration.vehicleType = value;
                },
              ),
            ),
            _PickerRow(
              label: 'Make',
              value: _registration.make,
              icon: Icons.factory_outlined,
              onTap: () => _pick(
                title: 'Make',
                options: _makes,
                selected: _registration.make,
                onSelected: (String value) {
                  _registration.make = value;
                  _registration.model = '';
                },
              ),
            ),
            _PickerRow(
              label: 'Model',
              value: _registration.model,
              icon: Icons.directions_car_filled_rounded,
              onTap: _registration.make.isEmpty
                  ? null
                  : () => _pick(
                        title: 'Model',
                        options: _models,
                        selected: _registration.model,
                        onSelected: (String value) =>
                            _registration.model = value,
                      ),
            ),
            _PickerRow(
              label: 'Color',
              value: _registration.color,
              icon: Icons.palette_outlined,
              swatch: _colors[_registration.color],
              onTap: () => _pick(
                title: 'Color',
                options: _colors.keys.toList(),
                selected: _registration.color,
                colors: _colors,
                onSelected: (String value) => _registration.color = value,
              ),
            ),
            _InputRow(
              controller: _yearController,
              label: 'Manufacture year',
              hint: 'e.g. 2018',
              icon: Icons.calendar_month_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: (_) => setState(() {}),
            ),
            _InputRow(
              controller: _plateController,
              label: 'Vehicle plate number',
              hint: 'e.g. SSD 1234',
              icon: Icons.pin_outlined,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(14),
              ],
              showDivider: false,
              onChanged: (_) => setState(() {}),
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleIllustration extends StatelessWidget {
  const _VehicleIllustration({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (type) {
      'Boda' => Icons.two_wheeler_rounded,
      'Rickshaw' => Icons.electric_rickshaw_rounded,
      _ => Icons.directions_car_filled_rounded,
    };
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -12,
            bottom: 0,
            child: Icon(icon, size: 178, color: AppColors.ink),
          ),
          const Positioned(
            left: 20,
            top: 18,
            child: Text(
              'ALPHA PLUS',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.swatch,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final bool complete = value.isNotEmpty;
    return Column(
      children: <Widget>[
        ListTile(
          enabled: onTap != null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
          leading: _StatusIcon(complete: complete, icon: icon, swatch: swatch),
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: Text(
            complete ? value : 'Select',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
          onTap: onTap,
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.showDivider = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final ValueChanged<String> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            _StatusIcon(complete: controller.text.isNotEmpty, icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                textCapitalization: textCapitalization,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        if (showDivider)
          Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.complete, required this.icon, this.swatch});

  final bool complete;
  final IconData icon;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: swatch ??
            (complete
                ? AppColors.primary
                : Theme.of(context).scaffoldBackgroundColor),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Icon(
        complete && swatch == null ? Icons.check_rounded : icon,
        color: complete && swatch == null
            ? AppColors.ink
            : Theme.of(context).colorScheme.onSurface,
        size: 22,
      ),
    );
  }
}
