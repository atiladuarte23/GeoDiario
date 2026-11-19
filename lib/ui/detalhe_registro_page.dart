import 'package:flutter/material.dart';

import '../data/registro.dart';
import '../data/registro_repository.dart';
import 'estilo.dart';

class DetalheRegistroPage extends StatefulWidget {
  const DetalheRegistroPage({
    super.key,
    required this.registro,
    required this.repositorio,
  });

  final Registro registro;
  final RegistroRepository repositorio;

  @override
  State<DetalheRegistroPage> createState() => _DetalheRegistroPageState();
}

class _DetalheRegistroPageState extends State<DetalheRegistroPage> {
  bool _excluindo = false;

  Future<void> _excluir() async {
    if (_excluindo) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: const Text(
          'O registro e a foto serão apagados do dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: terracota),
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _excluindo = true);
    try {
      await widget.repositorio.excluir(widget.registro);
    } catch (erro) {
      debugPrint('Falha ao excluir registro: $erro');
      if (!mounted) return;
      setState(() => _excluindo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir. Tente de novo.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final registro = widget.registro;
    return PopScope(
      canPop: !_excluindo,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do registro'),
          automaticallyImplyLeading: !_excluindo,
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1.15,
                  child: FotoRegistro(
                    caminho: registro.caminhoFoto,
                    recortar: false,
                  ),
                ),
              ),
              const SizedBox(height: 21),
              Text(
                registro.descricao,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.16,
                ),
              ),
              const SizedBox(height: 20),
              MetadadosRegistro(
                data: registro.dataHora,
                latitude: registro.latitude,
                longitude: registro.longitude,
              ),
            ],
          ),
        ),
        bottomNavigationBar: AcaoInferior(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: terracota,
              minimumSize: const Size(0, 54),
              side: const BorderSide(color: Color(0xFFE4BDB0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _excluindo ? null : _excluir,
            icon: const Icon(Icons.delete_outline),
            label: Text(_excluindo ? 'Excluindo…' : 'Excluir registro'),
          ),
        ),
      ),
    );
  }
}
