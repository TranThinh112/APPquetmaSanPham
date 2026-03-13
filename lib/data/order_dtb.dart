import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class OrderDatabase {
  static final OrderDatabase instance = OrderDatabase._init();

  static Database? _database;

  OrderDatabase._init();

  // In web builds, we keep data in memory rather than opening a SQLite file.
  final Map<String, Map<String, dynamic>> _inMemoryOrders = {};

  Future<Database> get database async {
    if (kIsWeb) {
      // Web does not support sqflite, so we never open a real DB here.
      throw UnsupportedError('SQLite is not supported on web. Use in-memory storage.');
    }

    if (_database != null) return _database!;


    _database = await _initDB('orders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print("Database path: $path");

    // nếu database chưa tồn tại → copy từ assets
    if (!await File(path).exists()) {

      ByteData data = await rootBundle.load("assets/orders_db.db");

      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path);
  }

  /// tìm đơn theo ID
  Future<Map<String, dynamic>?> getOrder(String id) async {
    if (kIsWeb) {
      return _inMemoryOrders[id];
    }

    final db = await instance.database;

    final result = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  /// lấy tất cả đơn hàng
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    if (kIsWeb) {
      return _inMemoryOrders.values.toList();
    }

    final db = await instance.database;
    return await db.query('orders');
  }

  /// đếm số lượng đơn hàng
  Future<int> countOrders() async {
    if (kIsWeb) {
      return _inMemoryOrders.length;
    }

    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    return Sqflite.firstIntValue(result) ?? 0;
  }

}