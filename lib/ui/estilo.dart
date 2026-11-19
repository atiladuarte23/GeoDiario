import 'dart:io';

import 'package:flutter/material.dart';

import '../data/registro.dart';

const floresta = Color(0xFF163C32);
const fundo = Color(0xFFF7F5ED);
const papel = Color(0xFFFFFDF7);
const borda = Color(0xFFE3E2D6);
const textoSuave = Color(0xFF54675D);
const terracota = Color(0xFFA33D26);

ThemeData temaGeoDiario() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: floresta).copyWith(
      primary: floresta,
      surface: papel,
      onSurface: floresta,
      error: terracota,
    ),
    scaffoldBackgroundColor: fundo,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: fundo,
      foregroundColor: floresta,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: floresta,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: papel,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borda),
      ),
      hintStyle: const TextStyle(color: textoSuave),
    ),
  );
}

class FotoRegistro extends StatelessWidget {
  const FotoRegistro({
    super.key,
    required this.caminho,
    this.miniatura = false,
    this.recortar = true,
  });

  final String caminho;
  final bool miniatura;
  final bool recortar;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE6EBE1),
      child: Image.file(
        File(caminho),
        width: double.infinity,
        height: double.infinity,
        fit: recortar ? BoxFit.cover : BoxFit.contain,
        cacheWidth: miniatura ? 960 : 1800,
        errorBuilder: (context, error, stack) =>
            const Center(child: Text('Foto indisponível')),
      ),
    );
  }
}

class MetadadosRegistro extends StatelessWidget {
  const MetadadosRegistro({
    super.key,
    required this.data,
    required this.latitude,
    required this.longitude,
  });

  final DateTime data;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: papel,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LinhaMetadados(
            icone: Icons.calendar_today_outlined,
            rotulo: 'Data e hora',
            valor: '${dataPorExtenso(data)} · ${horaCurta(data)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: borda),
          ),
          _LinhaMetadados(
            icone: Icons.location_on_outlined,
            rotulo: 'Localização',
            valor:
                'Lat. ${coordenada(latitude)}  ·  Long. ${coordenada(longitude)}',
          ),
        ],
      ),
    );
  }
}

class _LinhaMetadados extends StatelessWidget {
  const _LinhaMetadados({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE7ECE2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, size: 20, color: floresta),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rotulo,
                style: const TextStyle(color: textoSuave, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class AcaoInferior extends StatelessWidget {
  const AcaoInferior({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: fundo,
        border: Border(top: BorderSide(color: borda)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
