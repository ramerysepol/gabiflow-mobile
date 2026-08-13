import 'package:flutter/material.dart';

/// Tipos de compromisso da agenda.
///
/// Espelha `components/agenda/agenda-colors.ts` do painel — mesmos valores,
/// rotulos e cores. Antes o app tinha uma lista propria com `plenario` e
/// `agenda_publica`, que nao existem no painel: o evento criado no celular
/// aparecia como "Outro" na tela grande, e os tipos vindos do painel
/// (`audiencia`, `sessao`, `evento_publico`...) caiam no rotulo generico
/// "Evento" no celular.
class AgendaTipo {
  const AgendaTipo(this.valor, this.rotulo, this.cor);

  /// Valor gravado em `agendas.agenda_tipo`.
  final String valor;
  final String rotulo;
  final Color cor;
}

const List<AgendaTipo> agendaTipos = [
  AgendaTipo('reuniao', 'Reunião Institucional', Color(0xFF3B82F6)),
  AgendaTipo('audiencia', 'Audiência Pública', Color(0xFF8B5CF6)),
  AgendaTipo('viagem', 'Viagem', Color(0xFFF59E0B)),
  AgendaTipo('atendimento_gabinete', 'Atendimento no Gabinete', Color(0xFF10B981)),
  AgendaTipo('visita', 'Visita Técnica', Color(0xFF06B6D4)),
  AgendaTipo('midia', 'Mídia', Color(0xFFEC4899)),
  AgendaTipo('sessao', 'Sessão Legislativa', Color(0xFF6366F1)),
  AgendaTipo('evento_publico', 'Evento Público', Color(0xFFEF4444)),
  AgendaTipo('campanha', 'Campanha', Color(0xFFF97316)),
  AgendaTipo('outro', 'Outro', Color(0xFF6B7280)),
];

const AgendaTipo agendaTipoPadrao = AgendaTipo(
  'outro',
  'Outro',
  Color(0xFF6B7280),
);

/// Nunca devolve nulo: tipo desconhecido (registro antigo, ou criado por outro
/// caminho) cai em "Outro" em vez de deixar o card sem cor nem rotulo.
AgendaTipo agendaTipoDe(String? valor) {
  if (valor == null || valor.isEmpty) return agendaTipoPadrao;
  final v = valor.trim().toLowerCase();
  for (final t in agendaTipos) {
    if (t.valor == v) return t;
  }
  return agendaTipoPadrao;
}

/// Rotulo curto para caber no selo do card da lista.
String agendaTipoRotuloCurto(String? valor) {
  final t = agendaTipoDe(valor);
  return switch (t.valor) {
    'reuniao' => 'Reunião',
    'audiencia' => 'Audiência',
    'atendimento_gabinete' => 'Atendimento',
    'evento_publico' => 'Ev. Público',
    'sessao' => 'Sessão',
    'visita' => 'Visita',
    _ => t.rotulo,
  };
}
