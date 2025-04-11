import 'package:uuid/uuid.dart';

enum TransactionType { income, expense, transfer, savings }

class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final String categoryId;
  final TransactionType type;
  final String? accountId;
  final String? toAccountId; // For transfers

  Transaction({
    String? id,
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryId,
    required this.type,
    this.accountId,
    this.toAccountId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'categoryId': categoryId,
      'type': type.index,
      'accountId': accountId,
      'toAccountId': toAccountId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      description: map['description'],
      categoryId: map['categoryId'],
      type: TransactionType.values[map['type']],
      accountId: map['accountId'],
      toAccountId: map['toAccountId'],
    );
  }

  Transaction copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? description,
    String? categoryId,
    TransactionType? type,
    String? accountId,
    String? toAccountId,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
    );
  }
}
