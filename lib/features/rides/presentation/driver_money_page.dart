import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../wallet/data/driver_wallet_service.dart';
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
          final List<DriverTripRecord> accounted = completed
              .where((DriverTripRecord trip) => trip.hasTrustedAccounting)
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
          final int driverNetAll = accounted.fold<int>(
            0,
            (int total, DriverTripRecord trip) =>
                total + trip.driverNetFare!,
          );
          final bool hasLegacyCompletedRides =
              accounted.length != completed.length;

          return RefreshIndicator(
            onRefresh: () async =>
                Future<void>.delayed(const Duration(milliseconds: 300)),
            child: SingleChildScrollView(
              key: const Key('driverMoneyPage'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _MoneyHeader(),
                  const SizedBox(height: 16),
                  _DriverWalletCard(driverId: driverId),
                  const SizedBox(height: 12),
                  _MetricPair(
                    first: _MetricCard(
                      key: const Key('driverGrossEarnings'),
                      label: 'Gross earnings',
                      value: '${_money(grossAll)} SSP',
                      icon: Icons.payments_outlined,
                    ),
                    second: _MetricCard(
                      key: const Key('driverNetEarnings'),
                      label: 'Driver net',
                      value: '${_money(driverNetAll)} SSP',
                      icon: Icons.savings_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GrossFareCard(
                    amount: grossAll,
                    completedTrips: completed.length,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Trip activity',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
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
                  const SizedBox(height: 20),
                  _MetricPair(
                    first: _MetricCard(
                      key: const Key('driverTodayGross'),
                      label: 'Today',
                      value: '${_money(grossToday)} SSP',
                      icon: Icons.today_outlined,
                    ),
                    second: _MetricCard(
                      key: const Key('driverWeekGross'),
                      label: 'This week',
                      value: '${_money(grossWeek)} SSP',
                      icon: Icons.calendar_view_week_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettlementNotice(
                    hasLegacyCompletedRides: hasLegacyCompletedRides,
                  ),
                ],
              ),
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
                  value: trip.pickupDisplayAddress,
                ),
                const SizedBox(height: 14),
                _DetailLine(
                  icon: Icons.flag_rounded,
                  label: 'Destination',
                  value: trip.destinationDisplayAddress,
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
                if (trip.hasTrustedAccounting) ...<Widget>[
                  const SizedBox(height: 10),
                  _ValueRow(
                    label: 'Alpha fee (${trip.commissionLabel})',
                    value:
                        '${_money(trip.platformFee!)} ${trip.currencyCode}',
                  ),
                  const SizedBox(height: 10),
                  _ValueRow(
                    label: 'Driver net',
                    value:
                        '${_money(trip.driverNetFare!)} ${trip.currencyCode}',
                  ),
                  const SizedBox(height: 10),
                  _ValueRow(
                    label: 'Wallet settlement',
                    value: trip.settlementStatus == 'wallet_deducted'
                        ? 'Paid from wallet'
                        : 'Legacy record',
                  ),
                ],
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

class _MoneyHeader extends StatelessWidget {
  const _MoneyHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Money',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Wallet credit, completed rides and earnings.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _MetricPair extends StatelessWidget {
  const _MetricPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _DriverWalletCard extends StatelessWidget {
  const _DriverWalletCard({required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DriverWallet>(
      stream: DriverWalletService.instance.watchWallet(driverId),
      initialData: const DriverWallet.empty(),
      builder: (
        BuildContext context,
        AsyncSnapshot<DriverWallet> snapshot,
      ) {
        final DriverWallet wallet =
            snapshot.data ?? const DriverWallet.empty();
        final bool blocked = wallet.isSuspended || wallet.balance <= 0;
        final Color accent = blocked
            ? Theme.of(context).colorScheme.error
            : AppColors.primary;
        final String status = wallet.isSuspended
            ? 'Suspended'
            : wallet.balance <= 0
            ? 'Recharge required'
            : wallet.isLowBalance
            ? 'Low balance'
            : 'Ready for rides';

        return Container(
          key: const Key('driverWalletCard'),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: accent,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Alpha driver wallet',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_money(wallet.balance)} ${wallet.currencyCode}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                blocked
                    ? 'Visit the Alpha office to recharge or resolve your wallet before going online.'
                    : wallet.isLowBalance
                    ? 'Recharge soon. You can keep working while your balance covers the next ride fee.'
                    : 'The 10% Alpha fee is deducted automatically after each completed ride.',
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (snapshot.hasError) ...<Widget>[
                const SizedBox(height: 10),
                const Text(
                  'Wallet status is temporarily unavailable. Pull down to retry.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.payments_outlined, color: AppColors.primary, size: 19),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gross cash fares',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
  const _SettlementNotice({required this.hasLegacyCompletedRides});

  final bool hasLegacyCompletedRides;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasLegacyCompletedRides
                  ? 'Alpha deducts its 10% fee from your prepaid wallet after each newly completed ride. Older rides without trusted accounting remain visible only as legacy records.'
                  : 'Alpha deducts its 10% platform fee automatically from your prepaid wallet after each completed ride. Recharge securely at the Alpha office before the balance reaches zero.',
              style: const TextStyle(
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: trip.isCompleted
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : Theme.of(context).colorScheme.errorContainer,
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
                    Flexible(
                      child: Text(
                        '${_money(trip.grossFare)} ${trip.currencyCode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              _RouteLine(
                icon: Icons.my_location_rounded,
                value: trip.pickupDisplayAddress,
              ),
              const SizedBox(height: 8),
              _RouteLine(
                icon: Icons.flag_rounded,
                value: trip.destinationDisplayAddress,
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
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 32, color: AppColors.primary),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
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
