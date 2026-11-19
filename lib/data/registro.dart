import 'package:intl/intl.dart';

class Captura {
  const Captura({
    required this.caminhoTemporario,
    required this.dataHora,
    required this.latitude,
    required this.longitude,
  });

  final String caminhoTemporario;
  final DateTime dataHora;
  final double latitude;
  final double longitude;
}

class Registro {
  const Registro({
    required this.id,
    required this.descricao,
    required this.dataHora,
    required this.latitude,
    required this.longitude,
    required this.caminhoFoto,
  });

  factory Registro.doBanco(Map<String, Object?> dados, String caminhoFoto) {
    return Registro(
      id: dados['id'] as int,
      descricao: dados['descricao'] as String,
      dataHora: DateTime.fromMillisecondsSinceEpoch(dados['data_hora'] as int),
      latitude: (dados['latitude'] as num).toDouble(),
      longitude: (dados['longitude'] as num).toDouble(),
      caminhoFoto: caminhoFoto,
    );
  }

  final int id;
  final String descricao;
  final DateTime dataHora;
  final double latitude;
  final double longitude;
  final String caminhoFoto;
}

String dataPorExtenso(DateTime data) => DateFormat.yMMMMd('pt_BR').format(data);
String horaCurta(DateTime data) => DateFormat.Hm('pt_BR').format(data);

String coordenada(double valor) =>
    valor.toStringAsFixed(6).replaceAll('.', ',');
