import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/registro_repository.dart';
import 'ui/estilo.dart';
import 'ui/galeria_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(GeoDiarioApp(repositorio: RegistroSqlite()));
}

class GeoDiarioApp extends StatelessWidget {
  const GeoDiarioApp({super.key, required this.repositorio});

  final RegistroRepository repositorio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoDiário',
      debugShowCheckedModeBanner: false,
      theme: temaGeoDiario(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: GaleriaPage(repositorio: repositorio),
    );
  }
}
