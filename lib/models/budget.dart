import 'package:uuid/uuid.dart';

enum BudgetPeriod { daily, weekly, monthly, yearly, custom }

class Budget {
  final String id;
  final String name;
  final double amount;
  final BudgetPeriod period;
  final String? categoryId; // null means all categories
  final DateTime startDate;
  final DateTime? endDate; // null for recurring budgets

  Budget({
    String? id,
    required this.name,
    required this.amount,
    required this.period,
    this.categoryId,
    required this.startDate,
    this.endDate,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'period': period.index,
      'categoryId': categoryId,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      period: BudgetPeriod.values[map['period']],
      categoryId: map['categoryId'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
    );
  }

  Budget copyWith({
    String? id,
    String? name,
    double? amount,
    BudgetPeriod? period,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}
