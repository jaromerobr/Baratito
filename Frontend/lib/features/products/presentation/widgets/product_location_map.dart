/// Mapa (OpenStreetMap vía flutter_map) que muestra la ubicación de un
/// producto según su ciudad (`location_city`), con un marcador real.
///
/// Se eligió OpenStreetMap en vez de Google Maps: no requiere API key ni
/// cuenta de facturación, es gratis y su licencia es abierta (ODbL).
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';

/// Coordenadas de las principales ciudades de Ecuador (foco: Loja).
/// El marcador corresponde a la ciudad real del producto.
const Map<String, LatLng> _cityCoords = {
  'loja': LatLng(-3.99313, -79.20422),
  'quito': LatLng(-0.180653, -78.467834),
  'guayaquil': LatLng(-2.170998, -79.922359),
  'cuenca': LatLng(-2.900128, -79.005896),
  'ambato': LatLng(-1.241691, -78.619293),
  'machala': LatLng(-3.258611, -79.960556),
  'manta': LatLng(-0.967653, -80.708908),
  'santo domingo': LatLng(-0.253000, -79.175537),
};

LatLng _coordsFor(String city) {
  final key = city.trim().toLowerCase();
  return _cityCoords[key] ?? _cityCoords['loja']!;
}

class ProductLocationMap extends StatelessWidget {
  final String city;
  const ProductLocationMap({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final point = _coordsFor(city);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Ubicación · $city',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textPrimary)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 13,
                // Interacción básica (mover/zoom), sin rotación.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ec.edu.uide.baratito',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.error,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Ubicación aproximada según la ciudad del producto.',
            style: GoogleFonts.poppins(
                fontSize: 11, color: context.palette.textHint)),
      ],
    );
  }
}
