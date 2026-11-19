import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/registro.dart';
import '../services/localizacao.dart';
import 'estilo.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _camera;
  Future<void>? _liberando;
  String? _erro;
  bool _capturando = false;
  int _sessao = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_iniciarCamera());
  }

  Future<void> _iniciarCamera() async {
    final sessao = ++_sessao;
    try {
      await _liberando;
      if (!mounted || sessao != _sessao) return;
      final cameras = await availableCameras();
      if (!mounted || sessao != _sessao) return;
      if (cameras.isEmpty) {
        setState(() => _erro = 'Nenhuma câmera está disponível.');
        return;
      }
      final traseira = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final nova = CameraController(
        traseira,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _camera = nova;
      await nova.initialize();
      if (mounted && sessao == _sessao) setState(() => _erro = null);
    } on CameraException catch (erro) {
      if (!mounted || sessao != _sessao) return;
      _liberarCamera();
      setState(() {
        _erro = erro.code.startsWith('CameraAccess')
            ? 'Permita o acesso à câmera nos ajustes do dispositivo.'
            : 'Não foi possível abrir a câmera.';
      });
    }
  }

  void _liberarCamera() {
    _sessao++;
    final camera = _camera;
    _camera = null;
    if (camera != null) _liberando = camera.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _liberarCamera();
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      unawaited(_iniciarCamera());
    }
  }

  Future<void> _fotografar() async {
    final camera = _camera;
    if (_capturando || camera == null || !camera.value.isInitialized) return;
    setState(() => _capturando = true);
    final dataHora = DateTime.now();
    final posicaoFutura = obterPosicao().then<Position?>(
      (posicao) => posicao,
      onError: (Object _) => null,
    );
    try {
      final foto = await camera.takePicture();
      final posicao = await posicaoFutura;
      if (mounted &&
          posicao != null &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop(
          Captura(
            caminhoTemporario: foto.path,
            dataHora: dataHora,
            latitude: posicao.latitude,
            longitude: posicao.longitude,
          ),
        );
        return;
      }
      await descartarFotoTemporaria(foto.path);
      if (mounted) {
        _mostrarAviso(
          'Localização indisponível. Confira o GPS e fotografe de novo.',
        );
      }
    } on CameraException {
      if (mounted) {
        _mostrarAviso('Não foi possível tirar a foto. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liberarCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    final pronta = camera != null && camera.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('Câmera')),
      body: ColoredBox(
        color: const Color(0xFF0E201A),
        child: Center(
          child: pronta
              ? CameraPreview(camera)
              : _erro != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _erro!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
      bottomNavigationBar: AcaoInferior(
        child: FilledButton.icon(
          onPressed: pronta && !_capturando ? _fotografar : null,
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(_capturando ? 'Registrando foto e GPS…' : 'Tirar foto'),
        ),
      ),
    );
  }
}

Future<void> descartarFotoTemporaria(String caminho) async {
  try {
    final arquivo = File(caminho);
    if (await arquivo.exists()) await arquivo.delete();
  } on FileSystemException catch (erro) {
    debugPrint('Falha ao descartar foto temporária: $erro');
  }
}
