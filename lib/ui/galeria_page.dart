import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/registro.dart';
import '../data/registro_repository.dart';
import '../services/localizacao.dart';
import 'camera_page.dart';
import 'detalhe_registro_page.dart';
import 'estilo.dart';
import 'novo_registro_page.dart';

class GaleriaPage extends StatefulWidget {
  const GaleriaPage({super.key, required this.repositorio});

  final RegistroRepository repositorio;

  @override
  State<GaleriaPage> createState() => _GaleriaPageState();
}

class _GaleriaPageState extends State<GaleriaPage> {
  late Future<List<Registro>> _registros;
  bool _novaFoto = false;

  @override
  void initState() {
    super.initState();
    _registros = widget.repositorio.listar();
  }

  void _atualizar() {
    final registros = widget.repositorio.listar();
    setState(() {
      _registros = registros;
    });
  }

  void _avisar(String mensagem, {SnackBarAction? acao}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem), action: acao));
  }

  Future<void> _capturar() async {
    if (_novaFoto) return;
    setState(() => _novaFoto = true);
    Captura? captura;
    try {
      await prepararLocalizacao();
      if (!mounted) return;
      captura = await Navigator.of(
        context,
      ).push<Captura>(MaterialPageRoute(builder: (_) => const CameraPage()));
      if (!mounted || captura == null) return;
      final novaCaptura = captura;
      final salvo = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => NovoRegistroPage(
            captura: novaCaptura,
            repositorio: widget.repositorio,
          ),
        ),
      );
      if (mounted && salvo == true) {
        _atualizar();
        _avisar('Registro salvo.');
      }
    } on LocalizacaoIndisponivel catch (erro) {
      if (!mounted) return;
      final abrir = erro.abrirConfiguracoes;
      _avisar(
        erro.mensagem,
        acao: abrir == null
            ? null
            : SnackBarAction(
                label: 'Ajustes',
                onPressed: () async {
                  final abriu = await abrir();
                  if (!abriu && mounted) {
                    _avisar('Abra os ajustes de localização do dispositivo.');
                  }
                },
              ),
      );
    } catch (erro) {
      debugPrint('Falha ao iniciar captura: $erro');
      if (mounted) {
        _avisar('Não foi possível iniciar a captura. Tente de novo.');
      }
    } finally {
      if (captura != null) {
        await descartarFotoTemporaria(captura.caminhoTemporario);
      }
      if (mounted) setState(() => _novaFoto = false);
    }
  }

  Future<void> _abrirRegistro(Registro registro) async {
    final excluido = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DetalheRegistroPage(
          registro: registro,
          repositorio: widget.repositorio,
        ),
      ),
    );
    if (mounted && excluido == true) {
      _atualizar();
      _avisar('Registro excluído.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Cabecalho(),
          Expanded(
            child: FutureBuilder<List<Registro>>(
              future: _registros,
              builder: (context, estado) {
                if (estado.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (estado.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Não foi possível carregar os registros.'),
                          TextButton(
                            onPressed: _atualizar,
                            child: const Text('Tentar de novo'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final registros = estado.requireData;
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _TituloGaleria(total: registros.length),
                    ),
                    if (registros.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _GaleriaVazia(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverList.separated(
                          itemCount: registros.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, indice) {
                            final registro = registros[indice];
                            return _CartaoRegistro(
                              registro: registro,
                              aoAbrir: () => _abrirRegistro(registro),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AcaoInferior(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: terracota),
          onPressed: _novaFoto ? null : _capturar,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Nova foto'),
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: floresta,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 19),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAC39E),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: floresta,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'GeoDiário',
                    style: TextStyle(
                      color: Color(0xFFFFFAEC),
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TituloGaleria extends StatelessWidget {
  const _TituloGaleria({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meus registros',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 4),
            Text(
              total == 1 ? '1 foto salva' : '$total fotos salvas',
              style: const TextStyle(color: textoSuave),
            ),
          ],
        ],
      ),
    );
  }
}

class _GaleriaVazia extends StatelessWidget {
  const _GaleriaVazia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFE7ECE2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 34,
                color: floresta,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              'Nenhum registro ainda',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            const Text(
              'Toque em Nova foto para guardar um momento com a data e o local.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textoSuave),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoRegistro extends StatelessWidget {
  const _CartaoRegistro({required this.registro, required this.aoAbrir});

  final Registro registro;
  final VoidCallback aoAbrir;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: papel,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: borda),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoAbrir,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.95,
              child: FotoRegistro(
                caminho: registro.caminhoFoto,
                miniatura: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 12, 15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registro.descricao,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dataPorExtenso(registro.dataHora)} · ${horaCurta(registro.dataHora)}',
                          style: const TextStyle(
                            color: textoSuave,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 22, color: textoSuave),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
