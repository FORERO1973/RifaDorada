import 'package:flutter/material.dart';

class AppLocalization {
  final Locale locale;

  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  static const _localizedValues = {
    'es': {
      'welcome': 'Bienvenido a',
      'rifas_disponibles': 'Rifas Disponibles',
      'nueva': 'Nueva',
      'no_hay_rifas': 'No hay rifas disponibles',
      'crear_rifa': 'Crear Rifa',
      'seleccionar_numeros': 'Seleccionar Números',
      'por_numero': 'Por número',
      'total_numeros': 'Total números',
      'continuar': 'CONTINUAR',
      'gestionar_ventas': 'Gestionar Ventas',
      'estadisticas': 'Estadísticas',
      'recaudado': 'Recaudado',
      'pendiente': 'Pendiente',
      'potencial': 'Potencial',
      'vendidos': 'Vendidos',
      'libre': 'Libre',
      'reservado': 'Reservado',
      'pagado': 'Pagado',
      'tu_seleccion': 'Tu Selección',
    },
    'en': {
      'welcome': 'Welcome to',
      'rifas_disponibles': 'Available Raffles',
      'nueva': 'New',
      'no_hay_rifas': 'No raffles available',
      'crear_rifa': 'Create Raffle',
      'seleccionar_numeros': 'Select Numbers',
      'por_numero': 'Per number',
      'total_numeros': 'Total numbers',
      'continuar': 'CONTINUE',
      'gestionar_ventas': 'Manage Sales',
      'estadisticas': 'Statistics',
      'recaudado': 'Collected',
      'pendiente': 'Pending',
      'potencial': 'Potential',
      'vendidos': 'Sold',
      'libre': 'Free',
      'reservado': 'Reserved',
      'pagado': 'Paid',
      'tu_seleccion': 'Your Selection',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) async {
    return AppLocalization(locale);
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}
