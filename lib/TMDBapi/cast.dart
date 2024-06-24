class Cast {
  final int id;
  final String name;
  final String character;
  final String? profilePath; // Nullable, as profile_path might not always be present

  Cast({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  factory Cast.fromMap(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] as int,
      name: json['name'] as String,
      character: json['character'] as String,
      profilePath: json['profile_path'] as String?,
    );
  }
}
