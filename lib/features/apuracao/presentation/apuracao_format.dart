import 'package:intl/intl.dart';

import '../data/models/apuracao_candidato_model.dart';

/// Formatação numérica compartilhada das telas de Apuração ao vivo.
final _numFmt = NumberFormat.decimalPattern('pt_BR');
final _pctFmt = NumberFormat('#,##0.00', 'pt_BR');

/// Formata contagem de votos/seções com separador de milhar pt-BR.
String formatarVotosApuracao(int? valor) =>
    valor == null ? '—' : _numFmt.format(valor);

/// Formata percentual com 2 casas decimais e vírgula (ex.: "12,34%").
String formatarPctApuracao(num? valor) =>
    valor == null ? '—' : '${_pctFmt.format(valor)}%';

/// Formata horário HH:mm:ss local, sem depender de locale do `intl`.
String formatarHoraApuracao(DateTime? data) {
  if (data == null) return '—';
  final h = data.hour.toString().padLeft(2, '0');
  final m = data.minute.toString().padLeft(2, '0');
  final s = data.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Formata variação de votos com sinal (ex.: "+1.234" ou "-830"), separador
/// de milhar pt-BR. Números negativos já saem com "-" do próprio formatador.
String formatarSinalVotosApuracao(int? valor) {
  if (valor == null) return '—';
  final sinal = valor > 0 ? '+' : '';
  return '$sinal${_numFmt.format(valor)}';
}

/// Formata variação percentual com sinal (ex.: "+12,50%" ou "-3,20%").
String formatarSinalPctApuracao(num? valor) {
  if (valor == null) return '—';
  final sinal = valor > 0 ? '+' : '';
  return '$sinal${_pctFmt.format(valor)}%';
}

/// Formata a razão vs. 2022 usada na projeção final (ex.: 1.12 -> "+12%").
String formatarRazaoVs2022Apuracao(num razao) {
  final variacaoPct = (razao - 1) * 100;
  final sinal = variacaoPct >= 0 ? '+' : '';
  return '$sinal${variacaoPct.round()}%';
}

/// Formata horário HH:mm (sem segundos) — usado nos eixos de gráfico.
String formatarHoraCurtaApuracao(DateTime? data) {
  if (data == null) return '';
  final h = data.hour.toString().padLeft(2, '0');
  final m = data.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Rótulo curto da projeção (mesmo vocabulário do `ProjecaoBadge`), usado em
/// textos simples (compartilhamento, Modo TV) onde o badge colorido não cabe.
String rotuloProjecaoApuracao(String? projecao) => switch (projecao) {
  'eleito' => 'Eleito',
  'suplente' => 'Suplente',
  'segundo_turno' => '2º turno',
  'nao_eleito' => 'Não eleito',
  _ => 'Em apuração',
};

/// Monta o texto de compartilhamento do resultado de um candidato (usado no
/// botão "Compartilhar" da ficha e do Modo TV).
String textoCompartilharApuracao(ApuracaoCandidatoModel dados) {
  final c = dados.candidato;
  final geral = dados.geral;
  final resumo = dados.resumo;
  final posicao = geral?.posicao;
  final vagas = geral?.vagas;

  final linhas = <String>[
    '🗳️ Apuração ao vivo — ${c.cargoNome ?? 'cargo não informado'} '
        '(${(c.uf ?? '—').toUpperCase()})',
    '${c.nomeUrna} (${c.numero ?? '—'} · ${c.partido ?? '—'})',
    '✅ ${formatarVotosApuracao(geral?.votos)} votos · '
        '${formatarPctApuracao(geral?.pct)} dos válidos',
    if (posicao != null)
      '📍 $posicaoº${vagas != null ? ' de $vagas vagas' : ''} · '
          '${rotuloProjecaoApuracao(geral?.projecao)}',
    '📊 ${formatarPctApuracao(resumo?.pctSecoes)} das seções apuradas',
    'via GabiFlow',
  ];
  return linhas.join('\n');
}

/// Percentual com 1 casa decimal (ex.: "52,3%") — usado em seções e mapa.
String formatarPct1Apuracao(num? valor) =>
    valor == null ? '—' : '${valor.toStringAsFixed(1).replaceAll('.', ',')}%';
