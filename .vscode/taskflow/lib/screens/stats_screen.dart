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
  String _filter = 'day'; // 'day', 'week', 'month'
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

    if (_filter == 'day') {
      start = DateTime(now.year, now.month, now.day);
    } else if (_filter == 'week') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else {
      start = DateTime(now.year, now.month, 1);
    }

    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final expenses = await DBHelper.instance.getExpensesByDateRange(start, end);
    final tasks = await DBHelper.instance.getAllTasks();

    setState(() {
      _expenses = expenses;
      _tasks = tasks;
    });
  }

  double get _totalExpense => _expenses.fold(0, (s, e) => s + e.amount);
  int get _completedTasks => _tasks.where((t) => t.isCompleted).length;

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
      default: return 'Diğer';
    }
  }

  Color _categoryColor(String key) {
    switch (key) {
      case 'food': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'shopping': return Colors.purple;
      default: return Colors.grey;
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
            Row(
              children: [
                _filterBtn('Bugün', 'day'),
                const SizedBox(width: 8),
                _filterBtn('Bu Hafta', 'week'),
                const SizedBox(width: 8),
                _filterBtn('Bu Ay', 'month'),
              ],
            ),
            const SizedBox(height: 20),

            // Özet kartlar
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Toplam Harcama',
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
              const Text(
                'Kategori Dağılımı',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...totals.entries.map((entry) {
                final percent = _totalExpense > 0
                    ? entry.value / _totalExpense
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_categoryName(entry.key)),
                          Text('₺${entry.value.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          color: _categoryColor(entry.key),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Harcama listesi
            const Text(
              'Harcama Detayları',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_expenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Bu dönemde harcama yok.'),
                ),
              )
            else
              ..._expenses.map((e) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _categoryColor(e.category),
                        child: const Icon(Icons.attach_money,
                            color: Colors.white, size: 18),
                      ),
                      title: Text(e.title),
                      subtitle: Text(
                        DateFormat('dd.MM.yyyy').format(e.date),
                      ),
                      trailing: Text(
                        '₺${e.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _filterBtn(String label, String value) {
    final isSelected = _filter == value;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () {
          setState(() => _filter = value);
          _loadData();
        },
        child: Text(label),
      ),
    );
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}