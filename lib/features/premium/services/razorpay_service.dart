import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Represents the outcome of a Razorpay checkout session.
sealed class PaymentResult {}

class PaymentSuccess extends PaymentResult {
  final PaymentSuccessResponse response;
  PaymentSuccess(this.response);
}

class PaymentFailure extends PaymentResult {
  final PaymentFailureResponse response;
  PaymentFailure(this.response);
}

class PaymentExternalWallet extends PaymentResult {
  final ExternalWalletResponse response;
  PaymentExternalWallet(this.response);
}

/// Service that manages the Razorpay SDK lifecycle.
///
/// Create one instance per screen that needs payments, and call [dispose]
/// in the widget's [dispose] override.
class RazorpayService {
  late final Razorpay _razorpay;
  final _resultController = StreamController<PaymentResult>.broadcast();

  /// Stream of payment results emitted after the checkout sheet closes.
  Stream<PaymentResult> get results => _resultController.stream;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _resultController.add(PaymentSuccess(response));
  }

  void _handleFailure(PaymentFailureResponse response) {
    _resultController.add(PaymentFailure(response));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _resultController.add(PaymentExternalWallet(response));
  }

  /// Opens the Razorpay checkout sheet.
  ///
  /// [amountInPaise] must be in paise (₹20 = 2000 paise).
  /// [description] is shown on the checkout sheet.
  void openCheckout({
    required int amountInPaise,
    required String description,
    String? userName,
    String? userEmail,
    String? userContact,
  }) {
    final keyId = dotenv.env['RAZORPAY_KEY_ID'] ?? '';

    final options = <String, dynamic>{
      'key': keyId,
      'amount': amountInPaise,
      'name': 'AttendanceAI',
      'description': description,
      'prefill': {
        'name': userName ?? '',
        'email': userEmail ?? '',
        'contact': userContact ?? '',
      },
      'theme': {
        'color': '#6750A4', // Primary purple matching app theme
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _resultController.addError(e);
    }
  }

  /// Must be called in the owning widget's [dispose].
  void dispose() {
    _razorpay.clear();
    _resultController.close();
  }
}
