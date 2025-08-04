class Protein {
  final String name;
  final String formula;
  final String complete_name;
  final int atomCount;

  const Protein({
    required this.name,
    required this.formula,
    required this.complete_name,
    required this.atomCount,
  });

  // Factory constructor for creating a Protein from JSON
  factory Protein.fromJson(Map<String, dynamic> json) {
    return Protein(
      name: json['name'] ?? '',
      formula: json['formula'] ?? '',
      complete_name: json['complete_name'] ?? '',
      atomCount: json['atomCount'] ?? 0,
    );
  }

  // Convert Protein to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'formula': formula,
      'complete_name': complete_name,
      'atomCount': atomCount,
    };
  }
}
