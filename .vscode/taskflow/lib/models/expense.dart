class Expense {
  int? id;
  String title;
  double amount;
  String category; // 'food', 'transport', 'shopping', 'other'
  DateTime date;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    this.category = 'other',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'],
    title: map['title'],
    amount: map['amount'],
    category: map['category'],
    date: DateTime.parse(map['date']),
  );
}