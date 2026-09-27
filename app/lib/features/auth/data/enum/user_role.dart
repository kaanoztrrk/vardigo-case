/// Case'deki iki hesap (bkz. server/data/seed.json → users).
enum UserRole {
  employer('employer'),
  worker('worker');

  const UserRole(this.value);

  /// Sunucunun beklediği değer (POST /api/auth/login → role).
  final String value;
}
