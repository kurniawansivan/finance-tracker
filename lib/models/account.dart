import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

enum AccountType { cash, bank, creditCard, investment, savings }

class Account {
  final String id;
  final String name;
  final double initialBalance;
  final AccountType type;
  final Color color;
  final IconData icon;
  final bool includeInTotal;

  Account({
    String? id,
    required this.name,
    this.initialBalance = 0.0,
    required this.type,
    required this.color,
    required this.icon,
    this.includeInTotal = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initialBalance': initialBalance,
      'type': type.index,
      'colorValue': color.value,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'includeInTotal': includeInTotal ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      initialBalance: map['initialBalance'],
      type: AccountType.values[map['type']],
      color: Color(map['colorValue']),
      icon: IconData(
        map['iconCodePoint'],
        fontFamily: map['iconFontFamily'],
        fontPackage: map['iconFontPackage'],
      ),
      includeInTotal: map['includeInTotal'] == 1,
    );
  }

  Account copyWith({
    String? id,
    String? name,
    double? initialBalance,
    AccountType? type,
    Color? color,
    IconData? icon,
    bool? includeInTotal,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      includeInTotal: includeInTotal ?? this.includeInTotal,
    );
  }
}
