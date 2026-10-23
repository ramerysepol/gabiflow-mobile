import 'package:flutter/material.dart';

/// Estado de ordenação de uma tabela: coluna ativa (-1 = nenhuma) e sentido.
class OrdenacaoTabela {
  final int coluna;
  final bool asc;

  const OrdenacaoTabela({this.coluna = -1, this.asc = true});

  /// Tocar na coluna ativa inverte; numa nova, começa por [ascInicial].
  OrdenacaoTabela alternar(int col, {bool ascInicial = true}) => col == coluna
      ? OrdenacaoTabela(coluna: col, asc: !asc)
      : OrdenacaoTabela(coluna: col, asc: ascInicial);

  /// Ordena uma cópia da lista usando a chave da coluna ativa.
  List<T> aplicar<T>(
    List<T> itens,
    Comparable<dynamic> Function(T item, int coluna) chave,
  ) {
    if (coluna < 0) return itens;
    final copia = [...itens];
    copia.sort((x, y) {
      final r = chave(x, coluna).compareTo(chave(y, coluna));
      return asc ? r : -r;
    });
    return copia;
  }
}

class ColunaOrdenavel {
  final String label;
  final int flex;
  final bool direita;
  final Color? cor;

  const ColunaOrdenavel(this.label, {this.flex = 1, this.direita = false, this.cor});
}

/// Cabeçalho tocável com setinha ↑/↓ na coluna ativa.
class CabecalhoOrdenavel extends StatelessWidget {
  const CabecalhoOrdenavel({
    super.key,
    required this.colunas,
    required this.ordenacao,
    required this.onOrdenar,
    this.padding = const EdgeInsets.fromLTRB(28, 4, 28, 4),
  });

  final List<ColunaOrdenavel> colunas;
  final OrdenacaoTabela ordenacao;
  final ValueChanged<int> onOrdenar;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < colunas.length; i++)
            Expanded(
              flex: colunas[i].flex,
              child: InkWell(
                onTap: () => onOrdenar(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: colunas[i].direita
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          colunas[i].label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ordenacao.coluna == i
                                ? (colunas[i].cor ?? cs.primary)
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (ordenacao.coluna == i)
                        Icon(
                          ordenacao.asc
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 12,
                          color: colunas[i].cor ?? cs.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
