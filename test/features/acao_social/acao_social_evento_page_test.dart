import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gabiflow_mobile/features/acao_social/data/datasources/acao_social_remote_datasource.dart';
import 'package:gabiflow_mobile/features/acao_social/data/models/acao_social_models.dart';
import 'package:gabiflow_mobile/features/acao_social/presentation/pages/acao_social_evento_page.dart';
import 'package:gabiflow_mobile/features/acao_social/presentation/providers/acao_social_providers.dart';

class _FakeDs implements AcaoSocialRemoteDataSource {
  @override
  Future<List<EventoAcaoSocial>> listarEventos({String? status}) async => [];

  @override
  Future<EventoAcaoSocial> obterEvento(String id) async => EventoAcaoSocial(
        id: id,
        nome: 'Expresso da Saude de Santana da Parnaiba',
        tag: 'expresso-da-saude-de-santana-da-parnaiba',
        status: 'ativo',
        totalVagas: 27,
        totalUtilizadas: 5,
        totalEspecialidades: 3,
        dataEvento: DateTime(2026, 4, 5),
        localEvento: 'Centro de Saude',
      );

  @override
  Future<List<EspecialidadeEvento>> listarEspecialidades(String eventoId) async => [];

  @override
  Future<List<Cadastrado>> listarCadastrados(String tag, {String? busca}) async {
    final todos = [
      const Cadastrado(id: 41938, nome: 'Esther Oliveira Cardoso Dourado', telefone: '71992536300', cidade: 'Salvador', estado: 'BA'),
      const Cadastrado(id: 41926, nome: 'Iremar Lopes Dourado', telefone: '71981797243', cidade: 'Salvador', estado: 'BA'),
    ];
    if (busca == null || busca.isEmpty) return todos;
    return todos.where((c) => c.nome.toLowerCase().contains(busca.toLowerCase())).toList();
  }

  @override
  Future<List<Atendimento>> listarAtendimentos(String eventoId, {int? eleitorId, String? status}) async => [];

  @override
  Future<Atendimento> criarAtendimento({required String eventoId, required String especialidadeId, required int eleitorId}) =>
      throw UnimplementedError();

  @override
  Future<Atendimento> atualizarAtendimento(String id, Map<String, dynamic> body) => throw UnimplementedError();

  @override
  Future<CadastroPresencialResult> cadastroPresencial(Map<String, dynamic> body) => throw UnimplementedError();

  @override
  Future<List<int>> baixarFichaPdf(String atendimentoId) => throw UnimplementedError();

  @override
  Future<EnderecoCep?> buscarCep(String cep) async => null;
}

void main() {
  testWidgets('aba Cadastrados lista os municipes do evento', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          acaoSocialDataSourceProvider.overrideWithValue(_FakeDs()),
        ],
        child: const MaterialApp(
          home: AcaoSocialEventoPage(eventoId: 'e6836f83'),
        ),
      ),
    );
    // evento + cadastrados carregam de forma assincrona
    await tester.pumpAndSettle();

    expect(find.text('Expresso da Saude de Santana da Parnaiba'), findsWidgets);
    expect(find.text('2 cadastrados'), findsOneWidget);
    expect(find.text('Esther Oliveira Cardoso Dourado'), findsOneWidget);
    expect(find.text('Iremar Lopes Dourado'), findsOneWidget);
  });
}
