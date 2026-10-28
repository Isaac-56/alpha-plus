import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

/// Observe both parallel dependencies immediately: a GPS error must not become
/// unhandled while the server preflight is still pending (or vice versa).
Future<(A, B)> prepareDriverOnline<A extends Object, B extends Object>(
  Future<A> availability,
  Future<B> position,
) async {
  final List<Object> values = await Future.wait<Object>(<Future<Object>>[
    availability,
    position,
  ], eagerError: true);
  return (values[0] as A, values[1] as B);
}

/// One retry for transport failures. Approval, wallet and permission errors
/// require action and must never be retried or treated as an online session.
Future<T> retryDriverAvailability<T>(
  Future<T> Function() request, {
  Future<void> Function()? beforeRetry,
}) async {
  try {
    return await request();
  } on FirebaseFunctionsException catch (error) {
    if (!<String>{'unavailable', 'deadline-exceeded'}.contains(error.code)) {
      rethrow;
    }
  } on TimeoutException {
    // A cold function or interrupted connection can succeed on the next call.
  }
  await (beforeRetry?.call() ??
      Future<void>.delayed(const Duration(milliseconds: 500)));
  return request();
}
