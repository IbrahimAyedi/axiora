// valeur speciala nesta3mlouha fi copyWith
// bech nfar9ou bin field ma tbadalch w field t7ab t7otou null
const Object unset = Object();
// t7awel value jeya mel json l DateTime
DateTime? dateTimeFromJson(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}

// t7awel value l double, ken num wala String
double? doubleFromJson(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// t7awel value l Map<String, dynamic>
Map<String, dynamic>? mapFromJson(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }

  return null;
}

// t7awel value l List<String>
List<String> stringListFromJson(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }

  return const <String>[];
}

// ta3mel copy immutable lel map
Map<String, dynamic>? mapCopy(Map<String, dynamic>? value) {
  if (value == null) return null;
  return Map<String, dynamic>.unmodifiable(value);
}
// ta3mel copy immutable lel list

List<String> stringListCopy(List<String> value) {
  return List<String>.unmodifiable(value);
}
