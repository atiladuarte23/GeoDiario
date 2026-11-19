import 'dart:io';

import 'package:geolocator/geolocator.dart';

class LocalizacaoIndisponivel implements Exception {
  const LocalizacaoIndisponivel(this.mensagem, {this.abrirConfiguracoes});

  final String mensagem;
  final Future<bool> Function()? abrirConfiguracoes;
}

Future<void> prepararLocalizacao() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocalizacaoIndisponivel(
      'Ative a localização do dispositivo para registrar a foto.',
      abrirConfiguracoes: Geolocator.openLocationSettings,
    );
  }

  var permissao = await Geolocator.checkPermission();
  if (permissao == LocationPermission.denied) {
    permissao = await Geolocator.requestPermission();
  }
  if (permissao == LocationPermission.deniedForever) {
    throw const LocalizacaoIndisponivel(
      'Autorize o GeoDiário a acessar sua localização nos ajustes.',
      abrirConfiguracoes: Geolocator.openAppSettings,
    );
  }
  if (permissao == LocationPermission.denied) {
    throw const LocalizacaoIndisponivel(
      'Conceda a permissão de localização para fotografar.',
    );
  }
}

Future<Position> obterPosicao() {
  const limite = Duration(seconds: 20);
  final configuracao = Platform.isAndroid
      ? AndroidSettings(
          forceLocationManager: true,
          accuracy: LocationAccuracy.high,
          timeLimit: limite,
        )
      : const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: limite,
        );
  return Geolocator.getCurrentPosition(locationSettings: configuracao);
}
