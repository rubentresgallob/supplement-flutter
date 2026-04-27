class SupplementDatabaseModel {
  final String id;
  final String name;
  final String category;
  final List<String> forms;
  final String typicalDosage;

  const SupplementDatabaseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.forms,
    required this.typicalDosage,
  });

  factory SupplementDatabaseModel.fromJson(Map<String, dynamic> json) {
    return SupplementDatabaseModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      category: json['category'] as String,
      forms: (json['forms'] as List<dynamic>).map((e) => e.toString()).toList(),
      // El backend puede usar camelCase o snake_case
      typicalDosage: (json['typicalDosage'] ?? json['typical_dosage'] ?? '') as String,
    );
  }
}
