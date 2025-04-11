import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;
  final bool isSavings;

  Category({
    String? id,
    required this.name,
    required this.icon,
    required this.color,
    this.isIncome = false,
    this.isSavings = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.value,
      'isIncome': isIncome ? 1 : 0,
      'isSavings': isSavings ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: IconData(
        map['iconCodePoint'],
        fontFamily: map['iconFontFamily'],
        fontPackage: map['iconFontPackage'],
      ),
      color: Color(map['colorValue']),
      isIncome: map['isIncome'] == 1,
      isSavings: map['isSavings'] == 1,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    bool? isIncome,
    bool? isSavings,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isIncome: isIncome ?? this.isIncome,
      isSavings: isSavings ?? this.isSavings,
    );
  }
}
