/// Datos de entrega del pedido: se guardan en el checkout y como predeterminados
/// en el perfil (para precargarlos en la próxima compra).
library;

import '../../../core/supabase_client.dart';

class DeliveryDefaults {
  final String recipient;
  final String phone;
  final String address;
  final String reference;
  final String city;

  const DeliveryDefaults({
    required this.recipient,
    required this.phone,
    required this.address,
    required this.reference,
    required this.city,
  });
}

class DeliveryRepository {
  final _client = SupabaseClientHelper.client;

  /// Predeterminados del perfil para precargar el formulario.
  Future<DeliveryDefaults> getDefaults() async {
    final uid = _client.auth.currentUser?.id;
    const empty = DeliveryDefaults(
        recipient: '', phone: '', address: '', reference: '', city: 'Loja');
    if (uid == null) return empty;

    final data = await _client
        .from('profiles')
        .select('full_name, phone, address, address_reference, address_city')
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return empty;

    return DeliveryDefaults(
      recipient: (data['full_name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      reference: (data['address_reference'] as String?) ?? '',
      city: (data['address_city'] as String?) ?? 'Loja',
    );
  }

  /// Guarda los datos de entrega en el checkout y (por defecto) en el perfil.
  Future<void> save({
    required String checkoutId,
    required String recipient,
    required String phone,
    required String address,
    required String reference,
    required String city,
    bool saveDefault = true,
  }) async {
    final uid = _client.auth.currentUser?.id;

    await _client.from('checkouts').update({
      'delivery_recipient': recipient,
      'delivery_phone': phone,
      'delivery_address': address,
      'delivery_reference': reference,
      'delivery_city': city,
    }).eq('id', checkoutId);

    if (saveDefault && uid != null) {
      await _client.from('profiles').update({
        'phone': phone,
        'address': address,
        'address_reference': reference,
        'address_city': city,
      }).eq('id', uid);
    }
  }
}
