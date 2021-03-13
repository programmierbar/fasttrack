class Platform {
  static const ios = Platform('ios');
  static const android = Platform('android');
  static const values = [ios, android];

  final String name;
  const Platform(this.name);

  int get hashCode => name.hashCode;

  bool operator ==(dynamic other) => other is Platform && other.name == name;
  String toString() => name;
}
