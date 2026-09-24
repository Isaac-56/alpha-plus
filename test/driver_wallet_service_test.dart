import 'package:alpha_plus/features/wallet/data/driver_wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty wallet blocks online work', () {
    const DriverWallet wallet = DriverWallet.empty();

    expect(wallet.balance, 0);
    expect(wallet.canGoOnline, isFalse);
    expect(wallet.isLowBalance, isTrue);
  });

  test('funded wallet can work and reports low balance accurately', () {
    final DriverWallet wallet = DriverWallet.fromMap(<String, dynamic>{
      'balance': 15000,
      'lowBalanceThreshold': 20000,
      'status': 'active',
      'currencyCode': 'SSP',
      'lifetimeCredits': 50000,
      'lifetimeDebits': 35000,
    });

    expect(wallet.canGoOnline, isTrue);
    expect(wallet.isLowBalance, isTrue);
    expect(wallet.lifetimeCredits, 50000);
    expect(wallet.lifetimeDebits, 35000);
  });

  test('suspended wallet blocks work even with credit', () {
    final DriverWallet wallet = DriverWallet.fromMap(<String, dynamic>{
      'balance': 100000,
      'lowBalanceThreshold': 20000,
      'status': 'suspended',
    });

    expect(wallet.isSuspended, isTrue);
    expect(wallet.canGoOnline, isFalse);
  });
}
