import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Initialize Stripe payment sheet
  Future<PaymentSheetResult> initializePaymentSheet({
    required String bookingId,
    required double amount,
    required String currency,
    String? customerEmail,
  }) async {
    try {
      // Get payment intent from Cloud Function
      final callable = _functions.httpsCallable('createPaymentIntent');
      final result = await callable.call({
        'bookingId': bookingId,
        'amount': (amount * 100).toInt(), // Convert to cents
        'currency': currency.toLowerCase(),
        'customerEmail': customerEmail,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] != true) {
        return PaymentSheetResult(
          success: false,
          error: data['error']?['message'] ?? 'Erreur lors de la création du paiement',
        );
      }

      final clientSecret = data['data']['clientSecret'] as String;
      final customerId = data['data']['customerId'] as String?;
      final ephemeralKey = data['data']['ephemeralKey'] as String?;

      // Initialize Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          merchantDisplayName: 'UnCoachUneSalle',
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF2563EB),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 12,
            ),
          ),
          billingDetails: BillingDetails(
            email: customerEmail,
          ),
        ),
      );

      return PaymentSheetResult(
        success: true,
        clientSecret: clientSecret,
      );
    } catch (e) {
      return PaymentSheetResult(
        success: false,
        error: 'Erreur lors de l\'initialisation du paiement: ${e.toString()}',
      );
    }
  }

  // Present payment sheet and process payment
  Future<PaymentResult> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return PaymentResult(success: true);
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult(
          success: false,
          cancelled: true,
          error: 'Paiement annulé',
        );
      }
      return PaymentResult(
        success: false,
        error: e.error.localizedMessage ?? 'Erreur de paiement',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Erreur lors du paiement: ${e.toString()}',
      );
    }
  }

  // Confirm payment with card details (alternative method)
  Future<PaymentResult> confirmPayment({
    required String clientSecret,
    required CardFieldInputDetails cardDetails,
  }) async {
    try {
      // Create payment method from card details
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // Confirm payment intent
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethod.id,
          ),
        ),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        return PaymentResult(success: true);
      } else if (paymentIntent.status == PaymentIntentsStatus.RequiresAction) {
        // Handle 3D Secure if needed
        return PaymentResult(
          success: false,
          requires3DS: true,
          error: 'Authentification 3D Secure requise',
        );
      } else {
        return PaymentResult(
          success: false,
          error: 'Le paiement n\'a pas pu être finalisé',
        );
      }
    } on StripeException catch (e) {
      return PaymentResult(
        success: false,
        error: e.error.localizedMessage ?? 'Erreur de paiement',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Erreur lors du paiement: ${e.toString()}',
      );
    }
  }

  // Request refund via Cloud Function
  Future<RefundResult> requestRefund({
    required String bookingId,
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('processRefund');
      final result = await callable.call({
        'bookingId': bookingId,
        'reason': reason,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return RefundResult(
          success: true,
          refundId: data['data']['refundId'],
          amount: (data['data']['amount'] as num).toDouble(),
        );
      } else {
        return RefundResult(
          success: false,
          error: data['error']?['message'] ?? 'Erreur lors du remboursement',
        );
      }
    } catch (e) {
      return RefundResult(
        success: false,
        error: 'Erreur lors de la demande de remboursement: ${e.toString()}',
      );
    }
  }

  // Get payment methods saved for customer
  Future<List<PaymentMethodInfo>> getSavedPaymentMethods() async {
    try {
      final callable = _functions.httpsCallable('getPaymentMethods');
      final result = await callable.call({});

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final methods = (data['data']['paymentMethods'] as List<dynamic>)
            .map((m) => PaymentMethodInfo.fromMap(m as Map<String, dynamic>))
            .toList();
        return methods;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// Color class for Stripe appearance
class Color {
  final int value;
  const Color(this.value);
}

// Helper classes
class PaymentSheetResult {
  final bool success;
  final String? clientSecret;
  final String? error;

  PaymentSheetResult({
    required this.success,
    this.clientSecret,
    this.error,
  });
}

class PaymentResult {
  final bool success;
  final bool cancelled;
  final bool requires3DS;
  final String? error;

  PaymentResult({
    required this.success,
    this.cancelled = false,
    this.requires3DS = false,
    this.error,
  });
}

class RefundResult {
  final bool success;
  final String? refundId;
  final double? amount;
  final String? error;

  RefundResult({
    required this.success,
    this.refundId,
    this.amount,
    this.error,
  });
}

class PaymentMethodInfo {
  final String id;
  final String brand;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;

  PaymentMethodInfo({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
  });

  factory PaymentMethodInfo.fromMap(Map<String, dynamic> map) {
    return PaymentMethodInfo(
      id: map['id'] ?? '',
      brand: map['brand'] ?? 'unknown',
      last4: map['last4'] ?? '****',
      expiryMonth: map['expiryMonth'] ?? 0,
      expiryYear: map['expiryYear'] ?? 0,
      isDefault: map['isDefault'] ?? false,
    );
  }

  String get displayExpiry => '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}';

  String get brandIcon {
    switch (brand.toLowerCase()) {
      case 'visa':
        return '💳 Visa';
      case 'mastercard':
        return '💳 Mastercard';
      case 'amex':
        return '💳 American Express';
      default:
        return '💳 $brand';
    }
  }
}
