/// Contexto do Command Center IA: o candidato/parlamentar em análise.
/// Persiste em Hive para sobreviver a restarts.
class IaContexto {
  final String sequencial;
  final String nomeCandidato;
  final String siglaPartido;
  final String cargo;
  final int votosTotal;
  final String? fotoUrl;

  const IaContexto({
    required this.sequencial,
    required this.nomeCandidato,
    required this.siglaPartido,
    required this.cargo,
    this.votosTotal = 0,
    this.fotoUrl,
  });

  Map<String, dynamic> toJson() => {
        'sequencial': sequencial,
        'nome_candidato': nomeCandidato,
        'sigla_partido': siglaPartido,
        'cargo': cargo,
        'votos_total': votosTotal,
        'foto_url': fotoUrl,
      };

  factory IaContexto.fromJson(Map<String, dynamic> json) {
    return IaContexto(
      sequencial: json['sequencial']?.toString() ?? '',
      nomeCandidato: json['nome_candidato'] as String? ?? '',
      siglaPartido: json['sigla_partido'] as String? ?? '',
      cargo: json['cargo'] as String? ?? '',
      votosTotal: (json['votos_total'] as num?)?.toInt() ?? 0,
      fotoUrl: json['foto_url'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IaContexto && sequencial == other.sequencial;

  @override
  int get hashCode => sequencial.hashCode;
}
