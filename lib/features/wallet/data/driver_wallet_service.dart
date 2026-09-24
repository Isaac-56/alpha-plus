import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DriverWallet {
  const DriverWallet({
    required this.balance,
    required this.lowBalanceThreshold,
    required this.status,
    required this.currencyCode,
    required this.lifetimeCredits,
    required this.lifetimeDebits,
  });

  const DriverWallet.empty()
      : balance = 0,
        lowBalanceThreshold = 20000,
        status = 'active',
        currencyCode = 'SSP',
        lifetimeCredits = 0,
        lifetimeDebits = 0;

  final int balance;
  final int lowBalanceThreshold;
  final String status;
  final String currencyCode;
  final int lifetimeCredits;
  final int lifetimeDebits;

  bool get isSuspended => status == 'suspended';
  bool get isLowBalance => balance < lowBalanceThreshold;
  bool get canGoOnline => !isSuspended && balance > 0;

  factory DriverWallet.fromMap(Map<String, dynamic> data) {
    return DriverWallet(
      balance: _integer(data['balance']),
      lowBalanceThreshold: _integer(
        data['lowBalanceThreshold'],
        fallback: 20000,
      ),
      status: data['status'] is String
          ? (data['status'] as String).trim().toLowerCase()
          : 'active',
      currencyCode: data['currencyCode'] is String
          ? data['currencyCode'] as String
          : 'SSP',
      lifetimeCredits: _integer(data['lifetimeCredits']),
      lifetimeDebits: _integer(data['lifetimeDebits']),
    );
  }

  static int _integer(Object? value, {int fallback = 0}) {
    return value is num ? value.round() : fallback;
  }
}

class DriverWalletTransaction {
  const DriverWalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.currencyCode,
    required this.createdAt,
  });

  final String id;
  final String type;
  final int amount;
  final int balanceAfter;
  final String currencyCode;
  final DateTime? createdAt;

  bool get isCredit => type == 'top_up';

  factory DriverWalletTransaction.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? const <String, dynamic>{};
    final Timestamp? timestamp = data['createdAt'] is Timestamp
        ? data['createdAt'] as Timestamp
        : null;
    return DriverWalletTransaction(
      id: document.id,
      type: data['type'] is String ? data['type'] as String : '',
      amount: data['amount'] is num ? (data['amount'] as num).round() : 0,
      balanceAfter: data['balanceAfter'] is num
          ? (data['balanceAfter'] as num).round()
          : 0,
      currencyCode: data['currencyCode'] is String
          ? data['currencyCode'] as String
          : 'SSP',
      createdAt: timestamp?.toDate(),
    );
  }
}

class DriverWalletException implements Exception {
  const DriverWalletException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriverWalletService {
  DriverWalletService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: 'africa-south1');

  static final DriverWalletService instance = DriverWalletService();

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<DriverWallet> watchWallet(String driverId) {
    if (driverId.trim().isEmpty) {
      return Stream<DriverWallet>.value(const DriverWallet.empty());
    }
    try {
      return _firestore
          .collection('driver_wallets')
          .doc(driverId)
          .snapshots()
          .map(
            (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
                snapshot.exists
                ? DriverWallet.fromMap(
                    snapshot.data() ?? const <String, dynamic>{},
                  )
                : const DriverWallet.empty(),
          );
    } on Object {
      return Stream<DriverWallet>.value(const DriverWallet.empty());
    }
  }

  Stream<List<DriverWalletTransaction>> watchTransactions(String driverId) {
    if (driverId.trim().isEmpty) {
      return Stream<List<DriverWalletTransaction>>.value(
        const <DriverWalletTransaction>[],
      );
    }
    try {
      return _firestore
          .collection('driver_wallets')
          .doc(driverId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map(
            (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
                .map(DriverWalletTransaction.fromDocument)
                .toList(growable: false),
          );
    } on Object {
      return Stream<List<DriverWalletTransaction>>.value(
        const <DriverWalletTransaction>[],
      );
    }
  }

  Future<DriverWallet> confirmCanGoOnline() async {
    try {
      final HttpsCallableResult<dynamic> result =
          await _functions.httpsCallable('checkDriverWalletEligibility').call();
      final Object? rawData = result.data;
      if (rawData is! Map) {
        throw const DriverWalletException(
          'Alpha Plus could not confirm your wallet balance.',
        );
      }
      return DriverWallet.fromMap(Map<String, dynamic>.from(rawData));
    } on FirebaseFunctionsException catch (error) {
      throw DriverWalletException(
        error.message ??
            'Recharge your Alpha wallet at the office before going online.',
      );
    }
  }
}
