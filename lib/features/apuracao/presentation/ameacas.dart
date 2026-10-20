import '../data/models/apuracao_candidato_model.dart';

/// Candidato identificado como "ameaça" (ou concorrente direto) à vaga do
/// candidato principal: colega de partido perto da linha de corte ou
/// concorrente direto na mesma disputa (vizinho). Usado em "Quem está
/// ameaçando a vaga de X" no card "Acompanhando voto a voto".
class AmeacaCandidato {
  final String sqcand;
  final String? numero;
  final String nomeUrna;
  final String? partido;
  final int votos;
  final num? pct;
  final int? posicao;
  final String? projecao;

  /// Frase curta explicando por que o candidato aparece na lista.
  final String motivo;

  const AmeacaCandidato({
    required this.sqcand,
    this.numero,
    required this.nomeUrna,
    this.partido,
    this.votos = 0,
    this.pct,
    this.posicao,
    this.projecao,
    required this.motivo,
  });
}

/// Monta a lista de "quem está ameaçando a vaga" do candidato principal:
///
/// - colegas de partido/federação cuja posição na agremiação está a até 2
///   posições da posição do principal, ou a até 1 vaga da última vaga
///   projetada/confirmada do partido (`ocupa vaga do partido` quando a
///   posição do colega já está dentro das vagas, `disputa a vaga do
///   partido` quando está fora);
/// - concorrentes diretos (vizinhos) na mesma disputa (`Nº no estado`).
///
/// Exclui quem já está em [jaSeguidos] (inclui o próprio principal) e
/// limita a 6 itens, sem duplicar o mesmo candidato.
List<AmeacaCandidato> calcularAmeacasApuracao(
  ApuracaoCandidatoModel dados,
  Set<String> jaSeguidos,
) {
  final principalSqcand = dados.candidato.sqcand;
  final posAgrPrincipal = dados.geral?.posicaoAgr;
  final agremiacao = dados.agremiacao;
  final vagas = agremiacao?.vagas ?? 0;

  final candidatos = <AmeacaCandidato>[];

  if (agremiacao != null && posAgrPrincipal != null) {
    for (final colega in agremiacao.colegas) {
      if (colega.sqcand == principalSqcand) continue;
      if (jaSeguidos.contains(colega.sqcand)) continue;
      final pos = colega.posicaoAgr;
      if (pos == null) continue;
      final pertoDaPosicao = (pos - posAgrPrincipal).abs() <= 2;
      final pertoDaVaga = vagas > 0 && (pos - vagas).abs() <= 1;
      if (!pertoDaPosicao && !pertoDaVaga) continue;
      candidatos.add(
        AmeacaCandidato(
          sqcand: colega.sqcand,
          numero: colega.numero,
          nomeUrna: colega.nomeUrna,
          partido: colega.partido,
          votos: colega.votos,
          pct: colega.pct,
          posicao: pos,
          projecao: colega.projecao,
          motivo: pos <= vagas
              ? 'ocupa vaga do partido'
              : 'disputa a vaga do partido',
        ),
      );
    }
  }

  for (final v in dados.vizinhos) {
    if (v.sqcand == principalSqcand) continue;
    if (jaSeguidos.contains(v.sqcand)) continue;
    candidatos.add(
      AmeacaCandidato(
        sqcand: v.sqcand,
        numero: v.numero,
        nomeUrna: v.nomeUrna,
        partido: v.partido,
        votos: v.votos,
        pct: v.pct,
        posicao: v.posicao,
        projecao: v.projecao,
        motivo: v.posicao != null
            ? '${v.posicao}º no estado'
            : 'concorrente direto',
      ),
    );
  }

  final vistos = <String>{};
  final resultado = <AmeacaCandidato>[];
  for (final c in candidatos) {
    if (resultado.length >= 6) break;
    if (vistos.add(c.sqcand)) resultado.add(c);
  }
  return resultado;
}
