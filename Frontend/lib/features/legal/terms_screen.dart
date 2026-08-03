/// Términos y Condiciones de Baratito.
///
/// Pantalla estática y legible, accesible sin sesión (se enlaza desde el
/// checkbox del registro) y desde el perfil.
library;

import 'package:flutter/material.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: BaratitoAppBar(
        title: Text('Términos y Condiciones',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: const [
            _Updated('Última actualización: julio de 2026'),
            _Section(
              '1. Aceptación de los términos',
              'Al crear una cuenta en Baratito aceptas estos Términos y '
                  'Condiciones. Si no estás de acuerdo con alguno de ellos, '
                  'no utilices la aplicación. Baratito es una plataforma de '
                  'compra y venta de artículos de segunda mano entre personas, '
                  'con operación local en Loja, Ecuador.',
            ),
            _Section(
              '2. Qué es Baratito',
              'Baratito es un intermediario: conecta a compradores y '
                  'vendedores, gestiona el cobro de las compras y coordina la '
                  'entrega. Los artículos publicados pertenecen a los usuarios '
                  'vendedores, no a Baratito.',
            ),
            _Section(
              '3. Cuenta y verificación de identidad',
              'Para comprar o vender debes verificar tu identidad enviando '
                  'fotos de tu cédula (frontal y posterior) y una selfie en '
                  'vivo. Estas imágenes se usan exclusivamente para confirmar '
                  'que eres tú: se comparan de forma automática y, cuando es '
                  'necesario, las revisa una persona del equipo (máximo 2 '
                  'horas dentro del horario de atención, de 8:00 a 24:00). '
                  'Se almacenan cifradas en un espacio privado y nunca se '
                  'muestran a otros usuarios ni se comparten con terceros. '
                  'Eres responsable de la veracidad de los datos de tu cuenta.',
            ),
            _Section(
              '4. Publicaciones',
              'El vendedor es responsable de que sus artículos sean de su '
                  'propiedad, estén descritos con honestidad (estado, precio y '
                  'fotos reales) y sean de comercio lícito. Está prohibido '
                  'publicar: artículos robados o falsificados, armas, drogas, '
                  'medicamentos, animales, y en general cualquier bien cuya '
                  'venta esté restringida por la ley ecuatoriana. Baratito '
                  'puede retirar publicaciones que incumplan estas reglas.',
            ),
            _Section(
              '5. Compras y pagos',
              'El pago se realiza por transferencia bancaria a la cuenta '
                  'recaudadora de Baratito (Banco de Loja), escaneando el QR o '
                  'usando los datos de la cuenta que se muestran al pagar. El '
                  'total incluye el precio de los productos más el costo de '
                  'envío. Tras transferir, debes subir el comprobante en la '
                  'app: el sistema lo valida automáticamente y, si no es '
                  'posible, lo revisa el equipo. Baratito retiene una comisión '
                  'del 8% sobre el precio de los productos y el valor del '
                  'envío; el resto se transfiere al vendedor una vez '
                  'confirmado el pago.',
            ),
            _Section(
              '6. Envíos y entregas',
              'El costo de envío es de \$2 por pedido cuando compras a un '
                  'solo vendedor, o de \$1 por vendedor cuando el pedido '
                  'incluye artículos de dos o más vendedores (Baratito agrupa '
                  'los artículos y realiza una sola entrega). Los tiempos de '
                  'entrega se coordinan tras la confirmación del pago.',
            ),
            _Section(
              '7. Chat y conducta',
              'El chat existe para coordinar compras y ventas. No está '
                  'permitido el acoso, las estafas, el spam ni intentar '
                  'concretar pagos por fuera de la plataforma para evadir la '
                  'comisión. Las cuentas que incumplan estas normas pueden ser '
                  'suspendidas.',
            ),
            _Section(
              '8. Privacidad y datos personales',
              'Baratito almacena los datos de tu perfil, tus publicaciones, '
                  'mensajes, comprobantes de pago e imágenes de verificación '
                  'en servidores seguros (Supabase). Las imágenes sensibles '
                  '(cédula, selfie y comprobantes) viven en espacios privados '
                  'con acceso restringido al titular y al equipo de Baratito. '
                  'No vendemos ni compartimos tus datos con terceros. Puedes '
                  'solicitar la eliminación de tu cuenta y tus datos '
                  'escribiendo al correo de contacto.',
            ),
            _Section(
              '9. Notificaciones',
              'Al usar la app aceptas recibir notificaciones sobre tu '
                  'actividad (mensajes, ventas, pagos y verificación). Puedes '
                  'silenciarlas por categoría desde los ajustes de tu '
                  'dispositivo.',
            ),
            _Section(
              '10. Responsabilidad',
              'Las transacciones se realizan entre usuarios. Baratito media '
                  'en el cobro y la entrega, y ofrece la verificación de '
                  'identidad para reducir riesgos, pero no garantiza la '
                  'calidad ni el estado de los artículos, que son '
                  'responsabilidad del vendedor. Ante cualquier problema con '
                  'una compra, contáctanos y el equipo revisará el caso.',
            ),
            _Section(
              '11. Cambios a estos términos',
              'Baratito puede actualizar estos términos. Los cambios '
                  'relevantes se comunicarán dentro de la app y regirán desde '
                  'su publicación.',
            ),
            _Section(
              '12. Contacto',
              'Para dudas, reclamos o solicitudes sobre tus datos: '
                  'eg.pd2005@gmail.com · Loja, Ecuador.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Updated extends StatelessWidget {
  final String text;
  const _Updated(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 12, color: context.palette.textHint)),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(body,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.55,
                  color: context.palette.textPrimary)),
        ],
      ),
    );
  }
}
