/// Payment repository — platform settings, checkout payment + proof upload.
library;

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../core/supabase_client.dart';

/// Where the buyer pays (Baratito's collection info) + commission %.
class PlatformSettings {
  final double commissionPercent;
  final String bank;
  final String accountName;
  final String? accountNumber;
  final String? qrPath;

  const PlatformSettings({
    required this.commissionPercent,
    required this.bank,
    required this.accountName,
    this.accountNumber,
    this.qrPath,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> j) => PlatformSettings(
        commissionPercent: (j['commission_percent'] as num?)?.toDouble() ?? 10,
        bank: (j['payout_bank'] as String?) ?? 'Banco de Loja',
        accountName: (j['payout_account_name'] as String?) ?? 'Baratito',
        accountNumber: j['payout_account_number'] as String?,
        qrPath: j['payout_qr_path'] as String?,
      );
}

class CheckoutInfo {
  final String id;
  final double totalAmount;
  final double platformFeeTotal;
  final double shippingFee;
  final String status;
  final String? proofPath;

  const CheckoutInfo({
    required this.id,
    required this.totalAmount,
    required this.platformFeeTotal,
    required this.shippingFee,
    required this.status,
    this.proofPath,
  });

  /// Subtotal de los productos (total − envío).
  double get productsSubtotal => totalAmount - shippingFee;

  factory CheckoutInfo.fromJson(Map<String, dynamic> j) => CheckoutInfo(
        id: j['id'] as String,
        totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0,
        platformFeeTotal: (j['platform_fee_total'] as num?)?.toDouble() ?? 0,
        shippingFee: (j['shipping_fee'] as num?)?.toDouble() ?? 0,
        status: (j['status'] as String?) ?? 'pending_payment',
        proofPath: j['proof_path'] as String?,
      );
}

class PaymentRepository {
  final _client = SupabaseClientHelper.client;
  static const _bucket = 'payment-proofs';

  Future<PlatformSettings> getSettings() async {
    final data =
        await _client.from('platform_settings').select().eq('id', 1).single();
    return PlatformSettings.fromJson(data);
  }

  Future<CheckoutInfo> getCheckout(String id) async {
    final data =
        await _client.from('checkouts').select().eq('id', id).single();
    return CheckoutInfo.fromJson(data);
  }

  /// Sube el comprobante y lo envía con los datos del OCR.
  /// El backend decide: si el monto OCR cubre el total → 'paid' (automático);
  /// si no → 'awaiting_confirmation' (revisión del admin).
  /// Devuelve el estado resultante ('paid' | 'awaiting_confirmation').
  Future<String> submitProof(
    String checkoutId,
    Uint8List bytes, {
    double? ocrAmount,
    String? ocrReference,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Sin sesión.');

    final path = '$uid/$checkoutId.jpg';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
              contentType: 'image/jpeg', upsert: true),
        );

    final res = await _client.rpc('submit_payment_proof', params: {
      'p_checkout': checkoutId,
      'p_proof_path': path,
      'p_ocr_amount': ocrAmount,
      'p_ocr_ref': ocrReference,
    });
    return (res as Map)['status'] as String? ?? 'awaiting_confirmation';
  }

  /// URL pública del QR de cobro de Baratito (bucket platform-assets).
  static String? qrUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return SupabaseClientHelper.client.storage
        .from('platform-assets')
        .getPublicUrl(path);
  }
}
