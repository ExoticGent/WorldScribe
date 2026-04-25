import 'package:flutter_test/flutter_test.dart';

import 'package:worldscribe/core/constants/app_strings.dart';
import 'package:worldscribe/core/forms/form_validators.dart';

void main() {
  group('FormValidators.required', () {
    test('returns the required message for null', () {
      expect(FormValidators.required(null), AppStrings.requiredField);
    });

    test('returns the required message for empty', () {
      expect(FormValidators.required(''), AppStrings.requiredField);
    });

    test('returns the required message for whitespace-only', () {
      expect(FormValidators.required('   \t\n '), AppStrings.requiredField);
    });

    test('returns null for any non-blank value', () {
      expect(FormValidators.required('a'), isNull);
      expect(FormValidators.required('  hello  '), isNull);
    });
  });

  group('FormValidators.maxLength', () {
    test('returns null for null or empty input (composition friendly)', () {
      final validate = FormValidators.maxLength(10);
      expect(validate(null), isNull);
      expect(validate(''), isNull);
    });

    test('returns null for input within the cap', () {
      final validate = FormValidators.maxLength(5);
      expect(validate('hi'), isNull);
      expect(validate('exact'), isNull);
    });

    test('returns an error message when input exceeds the cap', () {
      final validate = FormValidators.maxLength(5);
      final error = validate('too long');
      expect(error, isNotNull);
      expect(error, contains('5'));
    });
  });

  group('FormValidators.requiredWithMaxLength', () {
    test('rejects null with the required message', () {
      final validate = FormValidators.requiredWithMaxLength(10);
      expect(validate(null), AppStrings.requiredField);
    });

    test('rejects whitespace-only with the required message', () {
      final validate = FormValidators.requiredWithMaxLength(10);
      expect(validate('   '), AppStrings.requiredField);
    });

    test('rejects too-long input with the length message', () {
      final validate = FormValidators.requiredWithMaxLength(3);
      final error = validate('overflow');
      expect(error, isNotNull);
      expect(error, isNot(AppStrings.requiredField));
      expect(error, contains('3'));
    });

    test('accepts non-blank input within the cap', () {
      final validate = FormValidators.requiredWithMaxLength(10);
      expect(validate('ok'), isNull);
    });
  });
}
