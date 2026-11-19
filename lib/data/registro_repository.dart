import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'registro.dart';

abstract interface class RegistroRepository {
  Future<List<Registro>> listar();
  Future<void> salvar(Captura captura, String descricao);
  Future<void> excluir(Registro registro);
}

class RegistroSqlite implements RegistroRepository {
  RegistroSqlite({
    DatabaseFactory? factory,
    Future<Directory> Function()? diretorioDocumentos,
  }) : _factory = factory ?? databaseFactory,
       _diretorioDocumentos =
           diretorioDocumentos ?? getApplicationDocumentsDirectory;

  static const _tabela = 'registros';
  final DatabaseFactory _factory;
  final Future<Directory> Function() _diretorioDocumentos;

  Future<Database> _abrir() async {
    final documentos = await _diretorioDocumentos();
    return _factory.openDatabase(
      path.join(documentos.path, 'geodiario.db'),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (banco, _) => banco.execute('''
          CREATE TABLE registros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descricao TEXT NOT NULL CHECK(length(trim(descricao)) > 0),
            data_hora INTEGER NOT NULL,
            latitude REAL NOT NULL CHECK(latitude BETWEEN -90 AND 90),
            longitude REAL NOT NULL CHECK(longitude BETWEEN -180 AND 180),
            caminho_foto TEXT NOT NULL UNIQUE
          )
        '''),
      ),
    );
  }

  @override
  Future<List<Registro>> listar() async {
    final banco = await _abrir();
    final documentos = await _diretorioDocumentos();
    final dados = await banco.query(
      _tabela,
      orderBy: 'data_hora DESC, id DESC',
    );
    return dados.map((linha) {
      final relativo = linha['caminho_foto'] as String;
      return Registro.doBanco(linha, path.join(documentos.path, relativo));
    }).toList();
  }

  @override
  Future<void> salvar(Captura captura, String descricao) async {
    final banco = await _abrir();
    final documentos = await _diretorioDocumentos();
    final fotos = await Directory(path.join(documentos.path, 'fotos')).create();
    // O diretório exclusivo evita colisões em gravações simultâneas.
    final pasta = await fotos.createTemp('registro-');
    final foto = path.join(pasta.path, 'foto.jpg');
    try {
      await File(captura.caminhoTemporario).copy(foto);
      await banco.insert(_tabela, {
        'descricao': descricao.trim(),
        'data_hora': captura.dataHora.millisecondsSinceEpoch,
        'latitude': captura.latitude,
        'longitude': captura.longitude,
        'caminho_foto': 'fotos/${path.basename(pasta.path)}/foto.jpg',
      });
    } catch (_) {
      await _removerFoto(foto);
      rethrow;
    }
  }

  @override
  Future<void> excluir(Registro registro) async {
    final banco = await _abrir();
    await banco.delete(_tabela, where: 'id = ?', whereArgs: [registro.id]);
    await _removerFoto(registro.caminhoFoto);
  }

  Future<void> _removerFoto(String caminho) async {
    final foto = File(caminho);
    try {
      if (await foto.exists()) await foto.delete();
      if (await foto.parent.exists()) await foto.parent.delete();
    } on FileSystemException catch (erro) {
      // A linha já foi removida (ou nunca foi inserida). A foto órfã fica
      // na pasta privada do aplicativo se o sistema recusar a remoção.
      stderr.writeln('Falha ao limpar arquivo do GeoDiário: $erro');
    }
  }
}
