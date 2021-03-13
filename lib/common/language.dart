class Language {
  static const de = Language('de');
  static const en = Language('en');
  static const fr = Language('fr');
  static const es = Language('es');
  static const it = Language('it');
  static const br = Language('br');
  static const ru = Language('ru');
  static const nl = Language('nl');
  static const values = [de, en, fr, es, it, br, ru, nl];

  final String code;
  const Language(this.code);

  int get hashCode => code.hashCode;

  bool operator ==(dynamic other) => other is Language && other.code == code;
  String toString() => code;
}
