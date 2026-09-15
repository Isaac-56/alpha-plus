import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../dashboard/presentation/driver_detail_screens.dart';
import '../data/driver_trip_history_service.dart';

class DriverMoneyPage extends StatelessWidget {
  const DriverMoneyPage({
    required this.driverId,
    this.service,
    super.key,
  });

  final String driverId;
  final DriverTripHistoryService? service;

  DriverTripHistoryService get _service =>
      service ?? DriverTripHistoryService.instance;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<DriverTripRecord>>(
        stream: _service.watchTrips(driverId),
        initialData: const <DriverTripRecord>[],
        builder: (
          BuildContext context,
          AsyncSnapshot<List<DriverTripRecord>> snapshot,
        ) {
          final List<DriverTripRecord> trips =
              snapshot.data ?? const <DriverTripRecord>[];
          final List<DriverTripRecord> completed = trips
              .where((DriverTripRecord trip) => trip.isCompleted)
              .toList(growable: false);
          final DateTime now = DateTime.now();
          final DateTime today = DateTime(now.year, now.month, now.day);
          final DateTime weekStart = today.subtract(
            Duration(days: today.weekday - DateTime.monday),
          );
          final int grossToday = _sumSince(completed, today);
          final int grossWeek = _sumSince(completed, weekStart);
          final int grossAll = completed.fold<int>(
            0,
            (int total, DriverTripRecord trip) => total + trip.grossFare,
          );

          return RefreshIndicator(
            onRefresh: () async =>
                Future<void>.delayed(const Duration(milliseconds: 300)),
            child: ListView(
              key: const Key('driverMoneyPage'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Money',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Verified cash fares from completed rides.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const _CashBadge(),
                  ],
                ),
                const SizedBox(height: 18),
                _GrossFareCard(
                  amount: grossAll,
                  completedTrips: completed.length,
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricCard(
                        key: const Key('driverTodayGross'),
                        label: 'Today',
                        value: '${_money(grossToday)} SSP',
                        icon: Icons.today_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        key: const Key('driverWeekGross'),
                        label: 'This week',
                        value: '${_money(grossWeek)} SSP',
                        icon: Icons.calendar_view_week_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SettlementNotice(),
                const SizedBox(height: 10),
                _BalanceLimitLink(
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const BalanceLimitScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Trip activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Text(
                      '${trips.length} ${trips.length == 1 ? 'record' : 'records'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (snapshot.hasError)
                  const _MessageCard(
                    icon: Icons.cloud_off_outlined,
                    title: 'Trip activity unavailable',
                    body:
                        'Alpha Plus could not load your verified ride records. Check your connection and try again.',
                  )
                else if (trips.isEmpty)
                  const _MessageCard(
                    key: Key('driverTripHistoryEmpty'),
                    icon: Icons.route_outlined,
                    title: 'No trip activity yet',
                    body:
                        'Completed and cancelled rides will appear here after real trips are processed.',
                  )
                else
                  ...trips.map(
                    (DriverTripRecord trip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TripCard(
                        trip: trip,
                        onTap: () => _showTripDetails(context, trip),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static int _sumSince(List<DriverTripRecord> trips, DateTime start) {
    return trips.fold<int>(0, (int total, DriverTripRecord trip) {
      final DateTime? at = trip.activityAt;
      if (at == null || at.isBefore(start)) return total;
      return total + trip.grossFare;
    });
  }

  static Future<void> _showTripDetails(
    BuildContext context,
    DriverTripRecord trip,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: trip.isCompleted
                          ? AppColors.primary
                          : Theme.of(sheetContext).colorScheme.errorContainer,
                      child: Icon(
                        trip.isCompleted
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            trip.isCompleted
                                ? 'Completed trip'
                                : 'Cancelled trip',
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(_dateTimeLabel(trip.activityAt)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _DetailLine(
                  icon: Icons.my_location_rounded,
                  label: 'Pickup',
                  value: _safeAddress(trip.pickupAddress),
                ),
                const SizedBox(height: 14),
                _DetailLine(
                  icon: Icons.flag_rounded,
                  label: 'Destination',
                  value: _safeAddress(trip.destinationAddress),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _ValueRow(
                  label: 'Payment',
                  value: trip.paymentMethod == 'cash'
                      ? 'Cash'
                      : _titleCase(trip.paymentMethod),
                ),
                const SizedBox(height: 10),
                _ValueRow(
                  label: trip.isCompleted ? 'Gross fare' : 'Fare shown',
                  value: '${_money(trip.grossFare)} ${trip.currencyCode}',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CashBadge extends StatelessWidget {
  const _CashBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.payments_outlined, size: 17),
          SizedBox(width: 6),
          Text('Cash', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GrossFareCard extends StatelessWidget {
  const _GrossFareCard({required this.amount, required this.completedTrips});

  final int amount;
  final int completedTrips;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('driverGrossFareCard'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Gross cash fares',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${_money(amount)} SSP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedTrips completed ${completedTrips == 1 ? 'trip' : 'trips'}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
        ],
      ),
    );
  }
}

class _SettlementNotice extends StatelessWidget {
  const _SettlementNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'These are gross cash fares from completed trips. Platform fees, commission and settlement balances are not calculated until Alpha’s payout rules are defined.',
              style: TextStyle(height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceLimitLink extends StatelessWidget {
  const _BalanceLimitLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(Icons.account_balance_wallet_outlined),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Balance limit',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final DriverTripRecord trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: trip.isCompleted
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : Theme.of(context).colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      trip.isCompleted
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          trip.isCompleted ? 'Completed' : 'Cancelled',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          _dateTimeLabel(trip.activityAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (trip.isCompleted)
                    Text(
                      '${_money(trip.grossFare)} ${trip.currencyCode}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              _RouteLine(
                icon: Icons.my_location_rounded,
                value: _safeAddress(trip.pickupAddress),
              ),
              const SizedBox(height: 8),
              _RouteLine(
                icon: Icons.flag_rounded,
                value: _safeAddress(trip.destinationAddress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 36, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

String _money(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

String _safeAddress(String value) =>
    value.trim().isEmpty ? 'Address unavailable' : value.trim();

String _titleCase(String value) {
  final String normalized = value.trim();
  if (normalized.isEmpty) return 'Not specified';
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}

String _dateTimeLabel(DateTime? value) {
  if (value == null) return 'Time unavailable';
  final DateTime local = value.toLocal();
  final String month = _months[local.month - 1];
  final int hour12 = local.hour == 0
      ? 12
      : local.hour > 12
          ? local.hour - 12
          : local.hour;
  final String minute = local.minute.toString().padLeft(2, '0');
  final String period = local.hour >= 12 ? 'PM' : 'AM';
  return '$month ${local.day}, ${local.year} • $hour12:$minute $period';
}

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
