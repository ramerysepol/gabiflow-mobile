/// Normaliza texto para busca: minúsculas e sem acentos.
/// "SANTA BÁRBARA" e "santa barbara" viram a mesma chave; "PORTÃO" == "portao".
String semAcento(String s) {
  const de = 'áàâãäåéèêëíìîïóòôõöúùûüçñýÁÀÂÃÄÅÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑÝ';
  const para = 'aaaaaaeeeeiiiiooooouuuucnyAAAAAAEEEEIIIIOOOOOUUUUCNY';
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final i = de.indexOf(ch);
    b.write(i >= 0 ? para[i] : ch);
  }
  return b.toString().toLowerCase().trim();
}
