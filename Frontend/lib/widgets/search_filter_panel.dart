import 'package:flutter/material.dart';

class SearchFilterPanel extends StatefulWidget {
  final void Function(String, RangeValues, String) onFiltersChanged;

  const SearchFilterPanel({super.key, required this.onFiltersChanged});

  @override
  State<SearchFilterPanel> createState() => _SearchFilterPanelState();
}

class _SearchFilterPanelState extends State<SearchFilterPanel> {
  String _selectedCategory = 'Todas';
  RangeValues _priceRange = const RangeValues(0, 100);
  String _selectedSize = 'Cualquiera';

  void _updateCategory(String newCategory) {
    setState(() {
      _selectedCategory = newCategory;
    });
    widget.onFiltersChanged(_selectedCategory, _priceRange, _selectedSize);
  }

  void _updatePriceRange(RangeValues newRange) {
    setState(() {
      _priceRange = newRange;
    });
    widget.onFiltersChanged(_selectedCategory, _priceRange, _selectedSize);
  }

  void _updateSize(String newSize) {
    setState(() {
      _selectedSize = newSize;
    });
    widget.onFiltersChanged(_selectedCategory, _priceRange, _selectedSize);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          value: _selectedCategory,
          items: ['Todas', 'Camisetas', 'Pantalones', 'Abrigos']
              .map(
                (String cat) => DropdownMenuItem(value: cat, child: Text(cat)),
              )
              .toList(),
          onChanged: (String? value) {
            if (value != null) _updateCategory(value);
          },
        ),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 100,
          onChanged: _updatePriceRange,
        ),
        DropdownButton<String>(
          value: _selectedSize,
          items: ['Cualquiera', 'XS', 'S', 'M', 'L', 'XL']
              .map((String sz) => DropdownMenuItem(value: sz, child: Text(sz)))
              .toList(),
          onChanged: (String? value) {
            if (value != null) _updateSize(value);
          },
        ),
      ],
    );
  }
}
