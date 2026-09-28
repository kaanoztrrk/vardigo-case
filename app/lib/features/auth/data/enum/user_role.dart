/// The two accounts in the seed (server/data/seed.json → users).
enum UserRole {
  employer('employer'),
  worker('worker');

  const UserRole(this.value);

  /// Value the server expects in POST /api/auth/login.
  final String value;
}
