class Protein {
  final String name;
  final String formula;
  final String description;
  final int atomCount;

  const Protein({
    required this.name,
    required this.formula,
    required this.description,
    required this.atomCount,
  });

  // Factory constructor for creating a Protein from JSON
  factory Protein.fromJson(Map<String, dynamic> json) {
    return Protein(
      name: json['name'] ?? '',
      formula: json['formula'] ?? '',
      description: json['description'] ?? '',
      atomCount: json['atomCount'] ?? 0,
    );
  }

  // Convert Protein to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'formula': formula,
      'description': description,
      'atomCount': atomCount,
    };
  }
}
