import 'package:cloud_firestore/cloud_firestore.dart';

class FoodLogModel {
  final String id;
  final String userId;
  final DateTime date;
  final List<FoodEntry> meals;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodLogModel({
    required this.id,
    required this.userId,
    required this.date,
    this.meals = const [],
    this.totalCalories = 0.0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'meals': meals.map((e) => e.toMap()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FoodLogModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FoodLogModel(
      id: documentId,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      meals: (map['meals'] as List<dynamic>?)
          ?.map((e) => FoodEntry.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      totalCalories: map['totalCalories']?.toDouble() ?? 0.0,
      totalProtein: map['totalProtein']?.toDouble() ?? 0.0,
      totalCarbs: map['totalCarbs']?.toDouble() ?? 0.0,
      totalFat: map['totalFat']?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory FoodLogModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return FoodLogModel.fromMap(data, snapshot.id);
  }

  FoodLogModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<FoodEntry>? meals,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate totals from meals
  FoodLogModel calculateTotals() {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final meal in meals) {
      calories += meal.totalCalories;
      protein += meal.totalProtein;
      carbs += meal.totalCarbs;
      fat += meal.totalFat;
    }

    return copyWith(
      totalCalories: calories,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFat: fat,
    );
  }
}

class FoodEntry {
  final String id;
  final String mealType; // breakfast, lunch, dinner, snack
  final List<FoodItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime timestamp;

  FoodEntry({
    required this.id,
    required this.mealType,
    this.items = const [],
    this.totalCalories = 0.0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealType': mealType,
      'items': items.map((e) => e.toMap()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] ?? '',
      mealType: map['mealType'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((e) => FoodItem.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      totalCalories: map['totalCalories']?.toDouble() ?? 0.0,
      totalProtein: map['totalProtein']?.toDouble() ?? 0.0,
      totalCarbs: map['totalCarbs']?.toDouble() ?? 0.0,
      totalFat: map['totalFat']?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  FoodEntry copyWith({
    String? id,
    String? mealType,
    List<FoodItem>? items,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    DateTime? timestamp,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      items: items ?? this.items,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Calculate totals from items
  FoodEntry calculateTotals() {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final item in items) {
      calories += item.totalCalories;
      protein += item.totalProtein;
      carbs += item.totalCarbs;
      fat += item.totalFat;
    }

    return copyWith(
      totalCalories: calories,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFat: fat,
    );
  }
}

class FoodItem {
  final String name;
  final String? barcode;
  final double quantity;
  final String unit; // grams, cups, pieces, etc.
  final double caloriesPerUnit;
  final double proteinPerUnit;
  final double carbsPerUnit;
  final double fatPerUnit;
  final String? imageUrl;
  final String? brand;

  FoodItem({
    required this.name,
    this.barcode,
    this.quantity = 1.0,
    this.unit = 'serving',
    this.caloriesPerUnit = 0.0,
    this.proteinPerUnit = 0.0,
    this.carbsPerUnit = 0.0,
    this.fatPerUnit = 0.0,
    this.imageUrl,
    this.brand,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'quantity': quantity,
      'unit': unit,
      'caloriesPerUnit': caloriesPerUnit,
      'proteinPerUnit': proteinPerUnit,
      'carbsPerUnit': carbsPerUnit,
      'fatPerUnit': fatPerUnit,
      'imageUrl': imageUrl,
      'brand': brand,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] ?? '',
      barcode: map['barcode'],
      quantity: map['quantity']?.toDouble() ?? 1.0,
      unit: map['unit'] ?? 'serving',
      caloriesPerUnit: map['caloriesPerUnit']?.toDouble() ?? 0.0,
      proteinPerUnit: map['proteinPerUnit']?.toDouble() ?? 0.0,
      carbsPerUnit: map['carbsPerUnit']?.toDouble() ?? 0.0,
      fatPerUnit: map['fatPerUnit']?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'],
      brand: map['brand'],
    );
  }

  FoodItem copyWith({
    String? name,
    String? barcode,
    double? quantity,
    String? unit,
    double? caloriesPerUnit,
    double? proteinPerUnit,
    double? carbsPerUnit,
    double? fatPerUnit,
    String? imageUrl,
    String? brand,
  }) {
    return FoodItem(
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      caloriesPerUnit: caloriesPerUnit ?? this.caloriesPerUnit,
      proteinPerUnit: proteinPerUnit ?? this.proteinPerUnit,
      carbsPerUnit: carbsPerUnit ?? this.carbsPerUnit,
      fatPerUnit: fatPerUnit ?? this.fatPerUnit,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
    );
  }

  // Calculate total nutrients based on quantity
  double get totalCalories => caloriesPerUnit * quantity;
  double get totalProtein => proteinPerUnit * quantity;
  double get totalCarbs => carbsPerUnit * quantity;
  double get totalFat => fatPerUnit * quantity;
}
