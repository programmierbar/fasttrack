T enumfromString<T>(List<T> values, String value) {
  return values.firstWhere((it) => enumToString(it) == value);
}

String enumToString<T>(T member) {
  final name = member.toString();
  return name.substring(name.indexOf('.') + 1);
}
