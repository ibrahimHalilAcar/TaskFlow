import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';
import '../models/task.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _filter = 'day';
  List<Expense> _expenses = [];
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (_filter == 'day') {
      start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_filter == 'week') {
      final weekDay = now.weekday;
      start = DateTime(now.year, now.month, now.day - (weekDay - 1), 0, 0, 0);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else {
      start = DateTime(now.year, now.month, 1, 0, 0, 0);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    final expenses =
        await DBHelper.instance.getExpensesByDateRange(start, end);
    final tasks = await DBHelper.instance.getAllTasks();

    setState(() {
      _expenses = expenses;
      _tasks = tasks;
    });
  }

  double get _totalExpense =>
      _expenses.fold(0, (s, e) => s + e.amount);

  int get _completedTasks =>
      _tasks.where((t) => t.isCompleted).length;

  Map<String, double> get _categoryTotals {
    final map = <String, double>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  String _categoryName(String key) {
    switch (key) {
      case 'food': return 'Yemek';
      case 'transport': return 'Ulaşım';
      case 'shopping': return 'Alışveriş';
      case 'health': return 'Sağlık';
      case 'education': return 'Eğitim';
      case 'entertainment': return 'Eğlence';
      case 'bills': return 'Faturalar';
      default: return 'Diğer';
    }
  }

  Color _categoryColor(String key) {
    switch (key) {
      case 'food': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'shopping': return Colors.purple;
      case 'health': return Colors.red;
      case 'education': return Colors.indigo;
      case 'entertainment': return Colors.pink;
      case 'bills': return Colors.teal;
      default: return Colors.grey;
    }
  }

  String _filterTitle() {
    switch (_filter) {
      case 'day': return 'Bugün';
      case 'week': return 'Bu Hafta';
      default: return 'Bu Ay';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _categoryTotals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistik'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtre butonları
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _filterBtn('Bugün', 'day'),
                  _filterBtn('Bu Hafta', 'week'),
                  _filterBtn('Bu Ay', 'month'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Özet kartlar
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    '${_filterTitle()} Harcama',
                    '₺${_totalExpense.toStringAsFixed(2)}',
                    Icons.wallet,
                    Colors.red.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    'Tamamlanan Görev',
                    '$_completedTasks / ${_tasks.length}',
                    Icons.check_circle,
                    Colors.green.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kategori dağılımı
            if (totals.isNotEmpty) ...[
              Text(
                '${_filterTitle()} Kategori Dağılımı',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...totals.entries.map((entry) {
                final percent = _totalExpense > 0
                    ? entry.value / _totalExpense
                    : 0.0;
                final color = _categoryColor(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.circle,
                                  color: color, size: 10),
                              const SizedBox(width: 6),
                              Text(_categoryName(entry.key)),
                            ],
                          ),
                          Text(
                            '₺${entry.value.toStringAsFixed(2)}  (${(percent * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // Harcama yoksa mesaj
            if (_expenses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        '${_filterTitle()} harcama yok',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Harcama listesi
              Text(
                '${_filterTitle()} Harcamalar',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._expenses.map((e) {
                final color = _categoryColor(e.category);
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(Icons.attach_money,
                          color: color, size: 18),
                    ),
                    title: Text(e.title),
                    subtitle: Text(
                      '${_categoryName(e.category)}  •  ${DateFormat('dd.MM.yyyy').format(e.date)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      '₺${e.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterBtn(String label, String value) {
    final isSelected = _filter == value;
    final color = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _filter = value);
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}