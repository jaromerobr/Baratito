import 'package:flutter/material.dart';
import '../models/clothing.dart';

class ProductDetailCard extends StatelessWidget {
  final Clothing clothing;

  const ProductDetailCard({super.key, required this.clothing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.network(clothing.imageUrl, fit: BoxFit.cover),
        const SizedBox(height: 12),
        Text(clothing.name, style: const TextStyle(fontSize: 18)),
        Text('Talla: ${clothing.size}', style: const TextStyle(fontSize: 14)),
        Text(
          '\$${clothing.price.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(clothing.description, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
