import 'package:flutter/material.dart';

import '../data/registro.dart';
import '../data/registro_repository.dart';
import 'estilo.dart';

class NovoRegistroPage extends StatefulWidget {
  const NovoRegistroPage({
    super.key,
    required this.captura,
    required this.repositorio,
  });

  final Captura captura;
  final RegistroRepository repositorio;

  @override
  State<NovoRegistroPage> createState() => _NovoRegistroPageState();
}

class _NovoRegistroPageState extends State<NovoRegistroPage> {
  final _formulario = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  bool _salvando = false;

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);
    try {
      await widget.repositorio.salvar(widget.captura, _descricao.text);
    } catch (erro) {
      debugPrint('Falha ao salvar registro: $erro');
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar. Tente de novo.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captura = widget.captura;
    return PopScope(
      canPop: !_salvando,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Novo registro'),
          automaticallyImplyLeading: !_salvando,
        ),
        body: SafeArea(
          bottom: false,
          child: Form(
            key: _formulario,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 1.65,
                    child: FotoRegistro(caminho: captura.caminhoTemporario),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Título ou descrição',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _descricao,
                  enabled: !_salvando,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 180,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'O que você quer lembrar deste momento?',
                  ),
                  validator: (valor) => (valor ?? '').trim().isEmpty
                      ? 'Informe um título ou uma descrição.'
                      : null,
                ),
                const SizedBox(height: 8),
                MetadadosRegistro(
                  data: captura.dataHora,
                  latitude: captura.latitude,
                  longitude: captura.longitude,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AcaoInferior(
          child: FilledButton.icon(
            onPressed: _salvando ? null : _salvar,
            icon: const Icon(Icons.check),
            label: Text(_salvando ? 'Salvando…' : 'Salvar registro'),
          ),
        ),
      ),
    );
  }
}
