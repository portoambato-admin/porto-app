// lib/core/utils/input_formatters.dart
import 'package:flutter/services.dart';

/// Sólo letras (incluye acentos y espacios)
class LettersOnlyFormatter extends TextInputFormatter {
  static final _notAllowed = RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]');
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text.replaceAll(_notAllowed, '');
    final sel = TextSelection.collapsed(offset: t.length);
    return newValue.copyWith(text: t, selection: sel, composing: TextRange.empty);
  }
}

/// Sólo dígitos
class DigitsOnlyFormatter extends TextInputFormatter {
  static final _notDigit = RegExp(r'[^0-9]');
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text.replaceAll(_notDigit, '');
    final sel = TextSelection.collapsed(offset: t.length);
    return newValue.copyWith(text: t, selection: sel, composing: TextRange.empty);
  }
}

// helpers
final digitsOnly = DigitsOnlyFormatter();

String? notEmpty(String? v, {String msg = 'Requerido'}) {
  if ((v ?? '').trim().isEmpty) return msg;
  return null;
}
