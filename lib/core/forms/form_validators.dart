import '../constants/app_strings.dart';

/// Pure form-validation helpers shared by every TextFormField in the
/// app. Centralizing these keeps the rules consistent: a "required"
/// failure looks the same on every screen, and a length cap can be
/// raised app-wide by editing one place.
///
/// Each helper matches the `String? Function(String?)` signature that
/// Flutter's [FormFieldValidator] expects, so they drop straight into
/// `validator:` on a TextFormField.
class FormValidators {
  FormValidators._();

  /// Rejects null or whitespace-only input.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  /// Rejects input longer than [maxLength] characters. Returns null
  /// when the value is null or empty so this composes cleanly with
  /// [required] (run [required] first if the field is required).
  static String? Function(String?) maxLength(int maxLength) {
    return (String? value) {
      if (value == null) return null;
      if (value.length > maxLength) {
        return 'Too long (max $maxLength characters)';
      }
      return null;
    };
  }

  /// Combines [required] and [maxLength]: must be non-empty AND
  /// within the length cap. Used on most "name" fields, which are
  /// both mandatory and bounded.
  static String? Function(String?) requiredWithMaxLength(int maxLength) {
    final lengthCheck = FormValidators.maxLength(maxLength);
    return (String? value) {
      final requiredError = required(value);
      if (requiredError != null) return requiredError;
      return lengthCheck(value);
    };
  }
}
