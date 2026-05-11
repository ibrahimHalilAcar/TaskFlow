import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/task.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Task> _tasks = [];
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPriority = 'medium';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final tasks = await DBHelper.instance.getAllTasks();
    setState(() => _tasks = tasks);
  }

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) return;
    try {
      final task = Task(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        priority: _selectedPriority,
        createdAt: _selectedDate,
      );
      await DBHelper.instance.insertTask(task);
      _titleController.clear();
      _descController.clear();
      _selectedPriority = 'medium';
      _selectedDate = DateTime.now();
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateTask(Task task) async {
    await DBHelper.instance.updateTask(task);
    await _loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    await DBHelper.instance.deleteTask(id);
    await _loadTasks();
  }

  Future<void> _toggleTask(Task task) async {
    task.isCompleted = !task.isCompleted;
    await DBHelper.instance.updateTask(task);
    await _loadTasks();
  }

  // ── EKLEME BOTTOM SHEET ──
  void _showAddSheet() {
    _titleController.clear();
    _descController.clear();
    _selectedPriority = 'medium';
    _selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _taskForm(
        ctx: ctx,
        title: 'Yeni Görev',
        buttonLabel: 'Ekle',
        onSubmit: () async {
          if (_titleController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Başlık boş olamaz!')),
            );
            return;
          }
          await _addTask();
          if (mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── DÜZENLEME BOTTOM SHEET ──
  void _showEditSheet(Task task) {
    _titleController.text = task.title;
    _descController.text = task.description ?? '';
    _selectedPriority = task.priority;
    _selectedDate = task.createdAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _taskForm(
        ctx: ctx,
        title: 'Görevi Düzenle',
        buttonLabel: 'Kaydet',
        onSubmit: () async {
          if (_titleController.text.trim().isEmpty) return;
          task.title = _titleController.text.trim();
          task.description = _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim();
          task.priority = _selectedPriority;
          await _updateTask(task);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── DETAY DİALOG ──
  void _showDetailDialog(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.flag, color: _priorityColor(task.priority), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(task.title, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty) ...[
              const Text('Açıklama',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12)),
              const SizedBox(height: 4),
              Text(task.description!),
              const Divider(height: 20),
            ],
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Öncelik: ${_priorityLabel(task.priority)}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  task.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: task.isCompleted ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(task.isCompleted ? 'Tamamlandı' : 'Devam ediyor'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${task.createdAt.day}.${task.createdAt.month}.${task.createdAt.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Sil butonu
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Sil'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteTask(task.id!);
            },
          ),
          // Düzenle butonu
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Düzenle'),
            onPressed: () {
              Navigator.pop(ctx);
              _showEditSheet(task);
            },
          ),
          // Tamamla/Geri al
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: Icon(task.isCompleted ? Icons.undo : Icons.check, size: 18),
            label: Text(task.isCompleted ? 'Geri Al' : 'Tamamla'),
            onPressed: () async {
              await _toggleTask(task);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // ── ORTAK FORM WİDGET ──
  Widget _taskForm({
    required BuildContext ctx,
    required String title,
    required String buttonLabel,
    required VoidCallback onSubmit,
  }) {
    return StatefulBuilder(
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
            // Başlık satırı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Başlık alanı
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Görev Başlığı *',
                hintText: 'Örn: Matematik ödevi',
                prefixIcon: const Icon(Icons.title),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Açıklama alanı
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Açıklama (isteğe bağlı)',
                hintText: 'Detayları buraya yaz...',
                prefixIcon: const Icon(Icons.notes),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
             const SizedBox(height: 12),
            const Text('Tarih', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  locale: const Locale('tr', 'TR'),
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

            // Öncelik seçimi
            const Text('Öncelik',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                _priorityChip('Düşük', 'low', Colors.green, setModalState),
                const SizedBox(width: 8),
                _priorityChip('Orta', 'medium', Colors.orange, setModalState),
                const SizedBox(width: 8),
                _priorityChip('Yüksek', 'high', Colors.red, setModalState),
              ],
            ),
            const SizedBox(height: 20),

            // Gönder butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(buttonLabel == 'Ekle' ? Icons.add : Icons.save),
                label: Text(buttonLabel, style: const TextStyle(fontSize: 16)),
                onPressed: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── YARDIMCI WİDGET VE FONKSİYONLAR ──
  Widget _priorityChip(
      String label, String value, Color color, StateSetter setModalState) {
    final isSelected = _selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setModalState(() => _selectedPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
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

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'high':
        return 'Yüksek';
      case 'medium':
        return 'Orta';
      default:
        return 'Düşük';
    }
  }

  Widget _listHeader(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _tasks.where((t) => !t.isCompleted).toList();
    final completed = _tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevlerim'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text('${pending.length} bekliyor'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Görev Ekle'),
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Henüz görev yok',
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('Aşağıdaki butona bas ve ekle!',
                      style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                if (pending.isNotEmpty) ...[
                  _listHeader('Devam Ediyor', pending.length, Colors.orange),
                  ...pending.map((t) => _taskTile(t)),
                ],
                if (completed.isNotEmpty) ...[
                  _listHeader('Tamamlandı', completed.length, Colors.green),
                  ...completed.map((t) => _taskTile(t)),
                ],
              ],
            ),
    );
  }

  Widget _taskTile(Task task) {
    final color = _priorityColor(task.priority);
    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Görevi Sil'),
          content: Text('"${task.title}" silinecek. Emin misin?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _deleteTask(task.id!),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            Text('Sil', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _showDetailDialog(task),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: task.isCompleted
                  ? Colors.grey.shade200
                  : color.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: GestureDetector(
              onTap: () => _toggleTask(task),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : null,
              ),
            ),
            subtitle: task.description != null && task.description!.isNotEmpty
                ? Text(
                    task.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  )
                : null,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _priorityLabel(task.priority),
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
