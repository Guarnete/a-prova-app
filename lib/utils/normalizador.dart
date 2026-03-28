class Normalizador {
  /// Converte qualquer texto para ID do Firestore:
  /// "Psicologia Educacional" → "psicologia-educacional"
  /// "Engenharia Informática" → "engenharia-informatica"
  static String cursoId(String texto) {
    const acentos = 'àáâãäçèéêëìíîïñòóôõöùúûüýÀÁÂÃÄÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ';
    const semAcentos = 'aaaaaaceeeeiiiinooooouuuuyAAAAAACEEEEIIIINOOOOOUUUUY';
    var resultado = texto.trim().toLowerCase();
    for (int i = 0; i < acentos.length; i++) {
      resultado = resultado.replaceAll(acentos[i], semAcentos[i].toLowerCase());
    }
    return resultado.replaceAll(' ', '-').replaceAll('_', '-');
  }
}