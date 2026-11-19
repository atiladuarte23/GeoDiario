import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geodiario/data/registro.dart';
import 'package:geodiario/data/registro_repository.dart';
import 'package:geodiario/main.dart';
import 'package:geodiario/ui/novo_registro_page.dart';
import 'package:intl/date_symbol_data_local.dart';

class _RepositorioEmMemoria implements RegistroRepository {
  final registros = <Registro>[];

  @override
  Future<List<Registro>> listar() async => List.of(registros);

  @override
  Future<void> salvar(Captura captura, String descricao) async {
    registros.add(
      Registro(
        id: 1,
        descricao: descricao.trim(),
        dataHora: captura.dataHora,
        latitude: captura.latitude,
        longitude: captura.longitude,
        caminhoFoto: captura.caminhoTemporario,
      ),
    );
  }

  @override
  Future<void> excluir(Registro registro) async {
    registros.remove(registro);
  }
}

final _captura = Captura(
  caminhoTemporario: 'foto-de-teste-ausente.jpg',
  dataHora: DateTime(2026, 11, 19, 8, 30),
  latitude: -19.851728,
  longitude: -43.969338,
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('exige descrição e mantém os metadados da captura ao salvar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 850);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final repositorio = _RepositorioEmMemoria();
    final navegador = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navegador,
        home: const Scaffold(body: Text('Galeria de teste')),
      ),
    );
    final resultado = navegador.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            NovoRegistroPage(captura: _captura, repositorio: repositorio),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um título ou uma descrição.'), findsOneWidget);
    expect(repositorio.registros, isEmpty);

    await tester.enterText(find.byType(TextFormField), 'Caminhada na Pampulha');
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();

    expect(await resultado, isTrue);
    final registro = repositorio.registros.single;
    expect(registro.descricao, 'Caminhada na Pampulha');
    expect(registro.dataHora, _captura.dataHora);
    expect(registro.latitude, _captura.latitude);
    expect(registro.longitude, _captura.longitude);
  });

  testWidgets('abre os detalhes e só exclui após confirmação', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 850);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final repositorio = _RepositorioEmMemoria();
    await repositorio.salvar(_captura, 'Caminhada na Pampulha');
    await tester.pumpWidget(GeoDiarioApp(repositorio: repositorio));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Caminhada na Pampulha'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes do registro'), findsOneWidget);
    expect(find.textContaining('-19,851728'), findsOneWidget);

    await tester.tap(find.text('Excluir registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repositorio.registros, hasLength(1));

    await tester.tap(find.text('Excluir registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(repositorio.registros, isEmpty);
    expect(find.text('Nenhum registro ainda'), findsOneWidget);
  });
}
