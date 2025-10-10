// lib/core/utils/slug.dart
//
// Utilidades para generar códigos "slug" (solo minúsculas, números y guiones)
// a partir de textos como “Sub-5” y un turno “tarde”.

/// Normaliza acentos y caracteres comunes del español.
String _normalizeSpanish(String s) {
  // reemplazos básicos (rápidos, sin dependencias)
  final repl = <RegExp, String>{
    RegExp(r'[áàäâÁÀÄÂ]'): 'a',
    RegExp(r'[éèëêÉÈËÊ]'): 'e',
    RegExp(r'[íìïîÍÌÏÎ]'): 'i',
    RegExp(r'[óòöôÓÒÖÔ]'): 'o',
    RegExp(r'[úùüûÚÙÜÛ]'): 'u',
    RegExp(r'[ñÑ]'): 'n',
    // símbolos comunes
    RegExp(r'[’‘´`¨^~]'): '',
  };

  var out = s;
  for (final entry in repl.entries) {
    out = out.replaceAll(entry.key, entry.value);
  }
  return out;
}

/// Convierte un texto a un slug: minúsculas, números y guiones.
/// - colapsa espacios/símbolos en '-'
/// - elimina guiones repetidos
/// - recorta guiones al inicio/fin
String slugify(String input) {
  // 1) lower + trim
  var s = input.toLowerCase().trim();

  // 2) normaliza acentos (es) y símbolos
  s = _normalizeSpanish(s);

  // 3) cualquier cosa no [a-z0-9] → '-'
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  // 4) colapsa guiones
  s = s.replaceAll(RegExp(r'-{2,}'), '-');

  // 5) recorta guiones al inicio/fin
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');

  return s;
}

/// Construye un código como "sub-5-tarde" a partir de nombre y turno opcional.
String buildCodigoFrom({required String nombre, String? turno}) {
  final base = slugify(nombre);
  final suf  = (turno == null || turno.trim().isEmpty) ? '' : '-${slugify(turno)}';
  // evita doble guion si base vacío (por validación no debería pasar, pero por si acaso)
  final code = (base + suf).replaceAll(RegExp(r'-{2,}'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return code;
}

/// Valida el formato del código (coincide con lo que acepta el back y los inputs).
bool isValidCodigo(String code) {
  // solo minúsculas, números y guiones; sin guiones al inicio/fin; sin dobles guiones
  return RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(code);
}
