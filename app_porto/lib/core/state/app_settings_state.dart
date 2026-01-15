import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias locales de la app (no dependen del backend).
///
/// Nota:
/// - Se guarda en SharedPreferences (Web y Mobile).
/// - Para cambios que deben reflejarse globalmente (tema, escalado de texto, etc.)
///   se consume desde [AppSettingsScope] en `main.dart`.
enum ReportExportFormat { pdf, excel }

extension ReportExportFormatX on ReportExportFormat {
  String get label {
    switch (this) {
      case ReportExportFormat.pdf:
        return 'PDF';
      case ReportExportFormat.excel:
        return 'Excel';
    }
  }

  String get storageValue => name;

  static ReportExportFormat fromStorage(String? v) {
    switch (v) {
      case 'csv':
        return ReportExportFormat.excel;
      case 'pdf':
      default:
        return ReportExportFormat.pdf;
    }
  }
}

class AppSettingsState extends ChangeNotifier {
  // Keys
  static const _kThemeMode = 'porto_settings_themeMode';
  static const _kTextScale = 'porto_settings_textScale';
  static const _kCompact = 'porto_settings_compactDensity';
  static const _kReduceAnim = 'porto_settings_reduceAnimations';
  static const _kInAppNotif = 'porto_settings_inAppNotifications';
  static const _kNotifBadge = 'porto_settings_notificationBadge';
  static const _kExcelEnabled = 'porto_settings_exportExcelEnabled';
  static const _kPdfEnabled = 'porto_settings_exportPdfEnabled';
  static const _kPreferredExport = 'porto_settings_preferredExport';
  static const _kConfirmDanger = 'porto_settings_confirmDestructive';

  SharedPreferences? _prefs;
  bool _loaded = false;

  bool get loaded => _loaded;

  // Defaults (pensados para producción)
  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;
  bool _compactDensity = false;
  bool _reduceAnimations = false;

  bool _inAppNotifications = true;
  bool _notificationBadge = true;

  bool _exportExcelEnabled = false; // por defecto OFF: evita complejidad en UX
  bool _exportPdfEnabled = true;
  ReportExportFormat _preferredExport = ReportExportFormat.pdf;

  bool _confirmDestructiveActions = true;

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;
  bool get compactDensity => _compactDensity;
  bool get reduceAnimations => _reduceAnimations;

  bool get inAppNotifications => _inAppNotifications;
  bool get notificationBadge => _notificationBadge;

  bool get exportExcelEnabled => _exportExcelEnabled;
  bool get exportPdfEnabled => _exportPdfEnabled;
  ReportExportFormat get preferredExport => _preferredExport;

  bool get confirmDestructiveActions => _confirmDestructiveActions;

  Future<void> load() async {
    if (_loaded) return;
    _prefs ??= await SharedPreferences.getInstance();

    final p = _prefs!;
    _themeMode = _themeModeFromString(p.getString(_kThemeMode));
    _textScale = _clampDouble(p.getDouble(_kTextScale) ?? 1.0, 0.85, 1.25);
    _compactDensity = p.getBool(_kCompact) ?? false;
    _reduceAnimations = p.getBool(_kReduceAnim) ?? false;

    _inAppNotifications = p.getBool(_kInAppNotif) ?? true;
    _notificationBadge = p.getBool(_kNotifBadge) ?? true;

    _exportExcelEnabled = p.getBool(_kExcelEnabled) ?? false;
    _exportPdfEnabled = p.getBool(_kPdfEnabled) ?? true;

    _preferredExport =
        ReportExportFormatX.fromStorage(p.getString(_kPreferredExport));
    _confirmDestructiveActions = p.getBool(_kConfirmDanger) ?? true;

    // Coherencia: si PDF está deshabilitado, al menos Excel debe estar habilitado
    if (!_exportPdfEnabled && !_exportExcelEnabled) {
      _exportPdfEnabled = true;
    }
    // Coherencia: si preferencia apunta a algo deshabilitado, corregimos
    if (_preferredExport == ReportExportFormat.excel && !_exportExcelEnabled) {
      _preferredExport = ReportExportFormat.pdf;
    }
    if (_preferredExport == ReportExportFormat.pdf && !_exportPdfEnabled) {
      _preferredExport = _exportExcelEnabled
          ? ReportExportFormat.excel
          : ReportExportFormat.pdf;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _persist() async {
    await _ensurePrefs();
    final p = _prefs!;

    await p.setString(_kThemeMode, _themeModeToString(_themeMode));
    await p.setDouble(_kTextScale, _textScale);
    await p.setBool(_kCompact, _compactDensity);
    await p.setBool(_kReduceAnim, _reduceAnimations);

    await p.setBool(_kInAppNotif, _inAppNotifications);
    await p.setBool(_kNotifBadge, _notificationBadge);

    await p.setBool(_kExcelEnabled, _exportExcelEnabled);
    await p.setBool(_kPdfEnabled, _exportPdfEnabled);

    await p.setString(_kPreferredExport, _preferredExport.storageValue);
    await p.setBool(_kConfirmDanger, _confirmDestructiveActions);
  }

  // -------------------------------
  // Setters (con persistencia)
  // -------------------------------

  void setThemeMode(ThemeMode v) {
    if (_themeMode == v) return;
    _themeMode = v;
    notifyListeners();
    _persist();
  }

  void setTextScale(double v) {
    final nv = _clampDouble(v, 0.85, 1.25);
    if ((_textScale - nv).abs() < 0.001) return;
    _textScale = nv;
    notifyListeners();
    _persist();
  }

  void setCompactDensity(bool v) {
    if (_compactDensity == v) return;
    _compactDensity = v;
    notifyListeners();
    _persist();
  }

  void setReduceAnimations(bool v) {
    if (_reduceAnimations == v) return;
    _reduceAnimations = v;
    notifyListeners();
    _persist();
  }

  void setInAppNotifications(bool v) {
    if (_inAppNotifications == v) return;
    _inAppNotifications = v;
    notifyListeners();
    _persist();
  }

  void setNotificationBadge(bool v) {
    if (_notificationBadge == v) return;
    _notificationBadge = v;
    notifyListeners();
    _persist();
  }

  void setExportExcelEnabled(bool v) {
    if (_exportExcelEnabled == v) return;
    _exportExcelEnabled = v;

    if (!_exportExcelEnabled && _preferredExport == ReportExportFormat.excel) {
      _preferredExport = ReportExportFormat.pdf;
    }
    // Aseguramos que al menos un formato esté activo
    if (!_exportExcelEnabled && !_exportPdfEnabled) {
      _exportPdfEnabled = true;
      _preferredExport = ReportExportFormat.pdf;
    }

    notifyListeners();
    _persist();
  }

  void setExportPdfEnabled(bool v) {
    if (_exportPdfEnabled == v) return;
    _exportPdfEnabled = v;

    if (!_exportPdfEnabled && _preferredExport == ReportExportFormat.pdf) {
      _preferredExport =
          _exportExcelEnabled ? ReportExportFormat.excel : ReportExportFormat.pdf;
    }
    if (!_exportPdfEnabled && !_exportExcelEnabled) {
      _exportExcelEnabled = true;
      _preferredExport = ReportExportFormat.excel;
    }

    notifyListeners();
    _persist();
  }

  void setPreferredExport(ReportExportFormat v) {
    if (_preferredExport == v) return;

    // Respetamos enable flags
    if (v == ReportExportFormat.excel && !_exportExcelEnabled) return;
    if (v == ReportExportFormat.pdf && !_exportPdfEnabled) return;

    _preferredExport = v;
    notifyListeners();
    _persist();
  }

  void setConfirmDestructiveActions(bool v) {
    if (_confirmDestructiveActions == v) return;
    _confirmDestructiveActions = v;
    notifyListeners();
    _persist();
  }

  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _textScale = 1.0;
    _compactDensity = false;
    _reduceAnimations = false;

    _inAppNotifications = true;
    _notificationBadge = true;

    _exportExcelEnabled = false;
    _exportPdfEnabled = true;
    _preferredExport = ReportExportFormat.pdf;

    _confirmDestructiveActions = true;

    notifyListeners();
    await _persist();
  }

  // -------------------------------
  // Helpers
  // -------------------------------

  static double _clampDouble(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  static ThemeMode _themeModeFromString(String? v) {
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode v) {
    switch (v) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsState> {
  const AppSettingsScope({
    super.key,
    required this.controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  final AppSettingsState controller;

  static AppSettingsState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(AppSettingsScope oldWidget) =>
      controller != oldWidget.controller;
}
