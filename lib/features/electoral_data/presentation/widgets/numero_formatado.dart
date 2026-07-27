import 'package:intl/intl.dart';

/// Formata números grandes em k/M para exibição em cards compactos.
String formatarVotos(int votos) {
  if (votos >= 1000000) {
    return '${(votos / 1000000).toStringAsFixed(1)}M';
  } else if (votos >= 1000) {
    return '${(votos / 1000).toStringAsFixed(1)}k';
  }
  return votos.toString();
}

/// Formata número inteiro com separador de milhar pt-BR.
String formatarNumero(int valor) {
  return NumberFormat('#,##0', 'pt_BR').format(valor);
}

/// Formata double com separador pt-BR e casas decimais.
String formatarDecimal(double valor, {int casas = 1}) {
  return NumberFormat('#,##0.${'0' * casas}', 'pt_BR').format(valor);
}

/// Formata valor monetário em reais.
String formatarMoeda(double valor) {
  return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
}
