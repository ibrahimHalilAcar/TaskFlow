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
  List<Task> _allTasks = [];
  bool _showTasks = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime _getStart() {
    final now = DateTime.now();
    if (_filter == 'day') {
      return DateTime(now.year, now.month, now.day, 0, 0, 0);
    } else if (_filter == 'week') {
      return DateTime(
          now.year, now.month, now.day - (now.weekday - 1), 0, 0, 0);
    } else {
      return DateTime(now.year, now.month, 1, 0, 0, 0);
    }
  }

  DateTime _getEnd() {
    final now = DateTime.now();
    if (_filter == 'day') {
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_filter == 'week') {
      final daysUntilSunday = 7 - now.weekday;
      final sunday = now.add(Duration(days: daysUntilSunday));
      return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
    } else {
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      return DateTime(now.year, now.month, lastDay, 23, 59, 59);
    }
  }

  bool _inRange(DateTime date) {
    final start = _getStart();
    final end = _getEnd();
    return !date.isBefore(start) && !date.isAfter(end);
  }

  Future<void> _loadData() async {
    final allExpenses = await DBHelper.instance.getAllExpenses();
    final filteredExpenses =
        allExpenses.where((e) => _inRange(e.date)).toList();

    final allTasks = await DBHelper.instance.getAllTasks();
    final filteredTasks =
        allTasks.where((t) => _inRange(t.createdAt)).toList();

    setState(() {
      _expenses = filteredExpenses;
      _allTasks = filteredTasks;
    });
  }

  Future<void> _toggleTask(Task task) async {
    task.isCompleted = !task.isCompleted;
    await DBHelper.instance.updateTask(task);
    await _loadData();
  }

  Future<void> _deleteTask(int id) async {
    await DBHelper.instance.deleteTask(id);
    await _loadData();
  }

  void _showTaskDetail(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController =
        TextEditingController(text: task.description ?? '');
    String selectedPriority = task.priority;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık satırı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Görev Detayı',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Durum göstergesi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: task.isCompleted
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : Icons.pending,
                        color: task.isCompleted
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.isCompleted
                            ? 'Tamamlandı'
                            : 'Devam ediyor',
                        style: TextStyle(
                          color: task.isCompleted
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd.MM.yyyy')
                            .format(task.createdAt),
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Başlık düzenle
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Görev Başlığı',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),

                // Açıklama düzenle
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),

                // Öncelik seçimi
                const Text('Öncelik',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _priorityChipModal(
                        'Düşük', 'low', Colors.green,
                        selectedPriority, (v) {
                      setModalState(() => selectedPriority = v);
                    }),
                    const SizedBox(width: 8),
                    _priorityChipModal(
                        'Orta', 'medium', Colors.orange,
                        selectedPriority, (v) {
                      setModalState(() => selectedPriority = v);
                    }),
                    const SizedBox(width: 8),
                    _priorityChipModal(
                        'Yüksek', 'high', Colors.red,
                        selectedPriority, (v) {
                      setModalState(() => selectedPriority = v);
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet',
                        style: TextStyle(fontSize: 16)),
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty)
                        return;
                      task.title = titleController.text.trim();
                      task.description =
                          descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim();
                      task.priority = selectedPriority;
                      await DBHelper.instance.updateTask(task);
                      await _loadData();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Tamamla / Geri al butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.isCompleted
                          ? Colors.orange
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(task.isCompleted
                        ? Icons.undo
                        : Icons.check_circle),
                    label: Text(
                      task.isCompleted
                          ? 'Tamamlandı — Geri Al'
                          : 'Tamamlandı Olarak İşaretle',
                      style: const TextStyle(fontSize: 15),
                    ),
                    onPressed: () async {
                      await _toggleTask(task);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Sil butonu
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Görevi Sil',
                        style: TextStyle(fontSize: 15)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Görevi Sil'),
                          content: Text(
                              '"${task.title}" silinecek. Emin misin?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(c, false),
                              child: const Text('İptal'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              onPressed: () =>
                                  Navigator.pop(c, true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deleteTask(task.id!);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priorityChipModal(
      String label,
      String value,
      Color color,
      String selected,
      Function(String) onTap) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  double get _totalExpense =>
      _expenses.fold(0, (s, e) => s + e.amount);

  Map<String, double> get _categoryTotals {
    final map = <String, double>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  String _filterTitle() {
    switch (_filter) {
      case 'day':
        return 'Bugün';
      case 'week':
        return 'Bu Hafta';
      default:
        return 'Bu Ay';
    }
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

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      default: return Colors.green;
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'high': return 'Yüksek';
      case 'medium': return 'Orta';
      default: return 'Düşük';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistik'),
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
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
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _showTasks = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: !_showTasks
                            ? color
                            : Colors.transparent,
                        borderRadius:
                            const BorderRadius.horizontal(
                                left: Radius.circular(10)),
                        border: Border.all(color: color),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wallet,
                              size: 16,
                              color: !_showTasks
                                  ? Colors.white
                                  : color),
                          const SizedBox(width: 6),
                          Text('Harcamalar',
                              style: TextStyle(
                                color: !_showTasks
                                    ? Colors.white
                                    : color,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _showTasks = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: _showTasks
                            ? color
                            : Colors.transparent,
                        borderRadius:
                            const BorderRadius.horizontal(
                                right: Radius.circular(10)),
                        border: Border.all(color: color),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checklist,
                              size: 16,
                              color: _showTasks
                                  ? Colors.white
                                  : color),
                          const SizedBox(width: 6),
                          Text('Görevler',
                              style: TextStyle(
                                color: _showTasks
                                    ? Colors.white
                                    : color,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _showTasks
                  ? _taskContent()
                  : _expenseContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseContent() {
    final totals = _categoryTotals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade400.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.red.shade400
                    .withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wallet,
                      color: Colors.red.shade400, size: 28),
                  const SizedBox(width: 10),
                  Text('${_filterTitle()} Toplam Harcama',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₺${_totalExpense.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
              Text(
                '${_expenses.length} harcama kaydı',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_expenses.isEmpty)
          _emptyState(Icons.receipt_long,
              '${_filterTitle()} harcama yok')
        else ...[
          if (totals.isNotEmpty) ...[
            const Text('Kategori Dağılımı',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...totals.entries.map((entry) {
              final percent = _totalExpense > 0
                  ? entry.value / _totalExpense
                  : 0.0;
              final color = _categoryColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.circle,
                              color: color, size: 10),
                          const SizedBox(width: 6),
                          Text(_categoryName(entry.key)),
                        ]),
                        Text(
                          '₺${entry.value.toStringAsFixed(2)} (${(percent * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 10,
                        backgroundColor:
                            Colors.grey.shade200,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
          Text(
              '${_filterTitle()} Harcamalar (${_expenses.length})',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._expenses.map((e) {
            final color = _categoryColor(e.category);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      color.withValues(alpha: 0.15),
                  child: Icon(Icons.attach_money,
                      color: color, size: 18),
                ),
                title: Text(e.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
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
    );
  }

  Widget _taskContent() {
    final completed =
        _allTasks.where((t) => t.isCompleted).toList();
    final pending =
        _allTasks.where((t) => !t.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade400
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.green.shade400
                          .withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade400,
                        size: 26),
                    const SizedBox(height: 8),
                    Text('${completed.length}',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade400)),
                    Text('Tamamlanan',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.orange.shade400
                          .withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.pending,
                        color: Colors.orange.shade400,
                        size: 26),
                    const SizedBox(height: 8),
                    Text('${pending.length}',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade400)),
                    Text('Bekleyen',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_allTasks.isEmpty)
          _emptyState(Icons.checklist,
              '${_filterTitle()} tarihinde görev yok')
        else ...[
          const Text('Öncelik Dağılımı',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...['high', 'medium', 'low'].map((p) {
            final count = _allTasks
                .where((t) => t.priority == p)
                .length;
            if (count == 0) return const SizedBox();
            final percent = _allTasks.isNotEmpty
                ? count / _allTasks.length
                : 0.0;
            final color = _priorityColor(p);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.flag,
                            color: color, size: 14),
                        const SizedBox(width: 6),
                        Text(_priorityLabel(p)),
                      ]),
                      Text(
                        '$count görev (${(percent * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12),
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

          if (completed.isNotEmpty) ...[
            Text('Tamamlananlar (${completed.length})',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...completed.map((t) => _taskCard(t)),
            const SizedBox(height: 12),
          ],

          if (pending.isNotEmpty) ...[
            Text('Bekleyenler (${pending.length})',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...pending.map((t) => _taskCard(t)),
          ],
        ],
      ],
    );
  }

  Widget _taskCard(Task task) {
    final color = _priorityColor(task.priority);
    return GestureDetector(
      onTap: () => _showTaskDetail(task),
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: GestureDetector(
            onTap: () => _toggleTask(task),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? Colors.green
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? Colors.green
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null &&
                  task.description!.isNotEmpty)
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12),
                ),
              Text(
                DateFormat('dd.MM.yyyy')
                    .format(task.createdAt),
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _priorityLabel(task.priority),
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16)),
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
}