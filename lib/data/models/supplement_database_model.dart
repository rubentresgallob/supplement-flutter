/// Suplemento del catálogo. Solo lo que se muestra: nombre, categoría y formas.
/// El catálogo NO propone dosis (ni funciones o beneficios): no es consejo sanitario.
class SupplementDatabaseModel {
  final String id;
  final String name;
  final String category;
  final List<String> forms;

  const SupplementDatabaseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.forms,
  });

  factory SupplementDatabaseModel.fromJson(Map<String, dynamic> json) {
    return SupplementDatabaseModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      category: json['category'] as String,
      forms: (json['forms'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }
}
