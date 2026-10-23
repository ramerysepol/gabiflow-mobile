import 'package:flutter/material.dart';

/// Vocabulário da Mesa de Demandas 2.0 (Spec §2): valores, rótulos e cores.
/// Os valores são os mesmos do banco e da API — nunca traduzir na rede.
abstract final class DemandaVocab {
  static const statusLista = [
    'nova',
    'em_analise',
    'em_andamento',
    'aguardando_retorno',
    'concluida',
    'cancelada',
  ];
  static const statusEncerrados = {'concluida', 'cancelada'};

  static const _statusRotulo = {
    'nova': 'Nova',
    'em_analise': 'Em análise',
    'em_andamento': 'Em andamento',
    'aguardando_retorno': 'Aguardando retorno',
    'concluida': 'Concluída',
    'cancelada': 'Cancelada',
  };
  static String status(String v) => _statusRotulo[v] ?? v;

  static const prioridadeLista = ['baixa', 'media', 'alta', 'urgente'];
  static const _prioridadeRotulo = {
    'baixa': 'Baixa',
    'media': 'Média',
    'alta': 'Alta',
    'urgente': 'Urgente',
  };
  static String prioridade(String v) => _prioridadeRotulo[v] ?? v;

  static const canalLista = [
    'whatsapp',
    'presencial',
    'telefone',
    'app',
    'site',
    'email',
    'outro',
  ];
  static const _canalRotulo = {
    'whatsapp': 'WhatsApp',
    'presencial': 'Presencial',
    'telefone': 'Telefone',
    'app': 'App',
    'site': 'Site',
    'email': 'E-mail',
    'outro': 'Outro',
  };
  static String canal(String v) => _canalRotulo[v] ?? v;

  static const tipoPedidoLista = [
    'consulta',
    'exame',
    'cirurgia',
    'medicamento',
    'internacao',
    'transporte',
    'outro',
  ];
  static const _tipoPedidoRotulo = {
    'consulta': 'Consulta',
    'exame': 'Exame',
    'cirurgia': 'Cirurgia',
    'medicamento': 'Medicamento',
    'internacao': 'Internação',
    'transporte': 'Transporte (TFD)',
    'outro': 'Outro',
  };
  static String tipoPedido(String v) => _tipoPedidoRotulo[v] ?? v;

  static const urgenciaLista = ['eletiva', 'prioritaria', 'urgente'];
  static const _urgenciaRotulo = {
    'eletiva': 'Eletiva',
    'prioritaria': 'Prioritária',
    'urgente': 'Urgente',
  };
  static String urgencia(String v) => _urgenciaRotulo[v] ?? v;

  static String area(String v) => v == 'saude' ? 'Saúde' : 'Geral';

  static const _encRotulo = {
    'enviado': 'Enviado',
    'respondido': 'Respondido',
    'sem_resposta': 'Sem resposta',
  };
  static String encaminhamento(String v) => _encRotulo[v] ?? v;

  // ── Cores (Tailwind do projeto: sky/violet/blue/amber/emerald/slate) ──────
  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color _par(BuildContext c, int claro, int escuro) =>
      Color(_dark(c) ? escuro : claro);

  static Color corStatus(BuildContext c, String v) => switch (v) {
    'nova' => _par(c, 0xFF0284C7, 0xFF38BDF8),
    'em_analise' => _par(c, 0xFF7C3AED, 0xFFA78BFA),
    'em_andamento' => _par(c, 0xFF2563EB, 0xFF60A5FA),
    'aguardando_retorno' => _par(c, 0xFFD97706, 0xFFFCD34D),
    'concluida' => _par(c, 0xFF059669, 0xFF34D399),
    _ => _par(c, 0xFF64748B, 0xFF94A3B8),
  };

  static Color corPrioridade(BuildContext c, String v) => switch (v) {
    'urgente' => _par(c, 0xFFDC2626, 0xFFF87171),
    'alta' => _par(c, 0xFFEA580C, 0xFFFB923C),
    'media' => _par(c, 0xFF2563EB, 0xFF60A5FA),
    _ => _par(c, 0xFF64748B, 0xFF94A3B8),
  };

  /// Acento da área Saúde (teal).
  static Color corSaude(BuildContext c) => _par(c, 0xFF0D9488, 0xFF2DD4BF);

  static IconData iconeArea(String v) =>
      v == 'saude' ? Icons.monitor_heart_rounded : Icons.inbox_rounded;

  static IconData iconeEvento(String tipo) => switch (tipo) {
    'criada' => Icons.add_circle_outline_rounded,
    'status' => Icons.swap_horiz_rounded,
    'comentario' => Icons.chat_bubble_outline_rounded,
    'atribuicao' => Icons.person_add_alt_1_outlined,
    'encaminhamento' => Icons.send_rounded,
    'resposta_orgao' => Icons.mark_email_read_outlined,
    'retorno_municipe' => Icons.forum_outlined,
    'anexo' => Icons.attach_file_rounded,
    'ia' => Icons.auto_awesome_rounded,
    'edicao' => Icons.edit_outlined,
    'prazo' => Icons.event_outlined,
    _ => Icons.circle_outlined,
  };
}
