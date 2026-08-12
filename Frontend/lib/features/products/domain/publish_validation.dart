/// Validation rules for the "publish article" form.
///
/// Extracted from [PublishProductScreen] so the rules can be unit tested
/// without pumping a widget. Messages are the ones already shown in the UI.
library;

class PublishValidation {
  PublishValidation._();

  /// Minimum characters for a listing title (after trimming).
  static const int minTitleLength = 5;

  /// A listing needs at least one photo before it can be submitted.
  static const int minPhotos = 1;

  /// Returns an error message, or null when the title is acceptable.
  static String? title(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < minTitleLength) {
      return 'Mínimo $minTitleLength caracteres';
    }
    return null;
  }

  /// Returns an error message, or null when the price is acceptable.
  ///
  /// Accepts both `380.00` and `380,00` (comma is the decimal separator
  /// commonly typed in Ecuador).
  static String? price(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Ingresa un precio válido';
    return null;
  }

  /// Whether the seller attached enough photos to submit the listing.
  static bool hasEnoughPhotos(int count) => count >= minPhotos;
}