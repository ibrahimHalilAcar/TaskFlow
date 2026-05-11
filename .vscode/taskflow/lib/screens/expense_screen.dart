import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Expense> _expenses = [];
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'food';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    final expenses = await DBHelper.instance.getAllExpenses();
    setState(() => _expenses = expenses);
  }

  Future<void> _addExpense() async {
    if (_titleController.text.trim().isEmpty) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    try {
      final expense = Expense(
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
      );
      await DBHelper.instance.insertExpense(expense);
      _titleController.clear();
      _amountController.clear();
      _selectedCategory = 'food';
      _selectedDate = DateTime.now();
      await _loadExpenses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateExpense(Expense expense) async {
    await DBHelper.instance.updateExpense(expense);
    await _loadExpenses();
  }

  Future<void> _deleteExpense(int id) async {
    await DBHelper.instance.deleteExpense(id);
    await _loadExpenses();
  }

  double get _total => _expenses.fold(0, (s, e) => s + e.amount);

  // ── EKLEME / DÜZENLEME BOTTOM SHEET ──
  void _showSheet({Expense? existing}) {
    if (existing != null) {
      _selectedDate = existing.date;
      _titleController.text = existing.title;
      _amountController.text = existing.amount.toString();
      _selectedCategory = existing.category;
    } else {
      _selectedDate = DateTime.now();

      _titleController.clear();
      _amountController.clear();
      _selectedCategory = 'food';
    }

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    existing != null ? 'Harcamayı Düzenle' : 'Yeni Harcama',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Harcama Adı *',
                  hintText: 'Örn: Öğle yemeği',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Tutar (₺) *',
                  hintText: 'Örn: 45.50',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const Text('Tarih',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setModalState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(ctx).colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Kategori',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const SizedBox(height: 12),

              // Kategori seçim grid
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.1,
                children: _categories.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return GestureDetector(
                    onTap: () =>
                        setModalState(() => _selectedCategory = entry.key),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? entry.value['color'] as Color
                            : (entry.value['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: entry.value['color'] as Color),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            entry.value['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : entry.value['color'] as Color,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white
                                  : entry.value['color'] as Color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(existing != null ? Icons.save : Icons.add),
                  label: Text(
                    existing != null ? 'Kaydet' : 'Ekle',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () async {
                    if (existing != null) {
                      if (_titleController.text.trim().isEmpty) return;
                      final amount =
                          double.tryParse(_amountController.text.trim());
                      if (amount == null || amount <= 0) return;
                      existing.title = _titleController.text.trim();
                      existing.amount = amount;
                      existing.category = _selectedCategory;
                      await _updateExpense(existing);
                    } else {
                      await _addExpense();
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DETAY DİALOG ──
  void _showDetailDialog(Expense expense) {
    final cat = _categories[expense.category]!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: (cat['color'] as Color).withOpacity(0.2),
              child:
                  Icon(cat['icon'] as IconData, color: cat['color'] as Color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(expense.title, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.attach_money, 'Tutar',
                '₺${expense.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _detailRow(
                cat['icon'] as IconData, 'Kategori', cat['label'] as String),
            const SizedBox(height: 8),
            _detailRow(
              Icons.calendar_today,
              'Tarih',
              '${expense.date.day}.${expense.date.month}.${expense.date.year}',
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Sil'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteExpense(expense.id!);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Düzenle'),
            onPressed: () {
              Navigator.pop(ctx);
              _showSheet(existing: expense);
            },
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Kategoriler
  final Map<String, Map<String, dynamic>> _categories = {
    'food': {
      'label': 'Yemek',
      'icon': Icons.restaurant,
      'color': Colors.orange,
    },
    'transport': {
      'label': 'Ulaşım',
      'icon': Icons.directions_bus,
      'color': Colors.blue,
    },
    'shopping': {
      'label': 'Alışveriş',
      'icon': Icons.shopping_bag,
      'color': Colors.purple,
    },
    'health': {
      'label': 'Sağlık',
      'icon': Icons.local_hospital,
      'color': Colors.red,
    },
    'education': {
      'label': 'Eğitim',
      'icon': Icons.school,
      'color': Colors.indigo,
    },
    'entertainment': {
      'label': 'Eğlence',
      'icon': Icons.movie,
      'color': Colors.pink,
    },
    'bills': {
      'label': 'Faturalar',
      'icon': Icons.receipt_long,
      'color': Colors.teal,
    },
    'other': {
      'label': 'Diğer',
      'icon': Icons.category,
      'color': Colors.grey,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcamalarım'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Toplam: ₺${_total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Harcama Ekle'),
      ),
      body: _expenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wallet, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Henüz harcama yok',
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('Aşağıdaki butona bas ve ekle!',
                      style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 90, top: 8),
              itemCount: _expenses.length,
              itemBuilder: (ctx, i) {
                final expense = _expenses[i];
                final cat = _categories[expense.category]!;
                return Dismissible(
                  key: Key('expense_${expense.id}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async => await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Harcamayı Sil'),
                      content:
                          Text('"${expense.title}" silinecek. Emin misin?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('İptal')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sil'),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) => _deleteExpense(expense.id!),
                  background: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        Text('Sil',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => _showDetailDialog(expense),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: (cat['color'] as Color).withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor:
                              (cat['color'] as Color).withOpacity(0.15),
                          child: Icon(cat['icon'] as IconData,
                              color: cat['color'] as Color, size: 20),
                        ),
                        title: Text(expense.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${cat['label']}  •  ${expense.date.day}.${expense.date.month}.${expense.date.year}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                        trailing: Text(
                          '₺${expense.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: cat['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
