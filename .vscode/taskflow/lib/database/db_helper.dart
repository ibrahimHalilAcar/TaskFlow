import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/expense.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'medium',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'other',
        date TEXT NOT NULL
      )
    ''');
  }

  // ──────────────── TASK CRUD ────────────────

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'createdAt DESC');
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<Task?> getTaskById(int id) async {
    final db = await database;
    final maps =
        await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────── EXPENSE CRUD ────────────────

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final maps =
        await db.query('expenses', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
        'expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpensesByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  // ──────────────── GENEL ────────────────

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('expenses');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}