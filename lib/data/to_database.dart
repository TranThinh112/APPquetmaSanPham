/// =============================================================
/// File: to_database.dart
/// Mô tả: Quản lý bảng transfer_orders (TO) trong SQLite
///        Thay thế TOStorage in-memory bằng lưu trữ persistent
/// =============================================================
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/to_model.dart';

class TODatabase {
  static final TODatabase instance = TODatabase._init();

  static Database? _database;

  TODatabase._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web.');
    }

    if (_database != null) return _database!;

    _database = await _initDB('transfer_orders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print("TO Database path: $path");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Tạo bảng transfer_orders khi database lần đầu tiên được tạo
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transfer_orders (
        maTO TEXT PRIMARY KEY,
        danhSachGoiHang TEXT,
        diaDiemGiaoHang TEXT,
        trangThai TEXT,
        ngayTao TEXT,
        totalWeight REAL DEFAULT 0
      )
    ''');
    
    // Bảng supplement: lưu danh sách chi tiết của mỗi gói hàng (tuỳ chọn)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS to_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        maTO TEXT NOT NULL,
        maGoiHang TEXT NOT NULL,
        trongLuong REAL,
        ngayThem TEXT,
        FOREIGN KEY (maTO) REFERENCES transfer_orders(maTO)
      )
    ''');

    print('✓ Bảng transfer_orders tạo thành công');
  }

  /// Thêm TO mới
  Future<void> addTO(TOModel to) async {
    final db = await instance.database;
    
    await db.insert(
      'transfer_orders',
      {
        'maTO': to.maTO,
        'danhSachGoiHang': to.danhSachGoiHang.join(','),
        'diaDiemGiaoHang': to.diaDiemGiaoHang,
        'trangThai': to.trangThai,
        'ngayTao': to.ngayTao.toIso8601String(),
        'totalWeight': to.totalWeight,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('✓ Đã thêm TO: ${to.maTO}');
  }

  /// Lấy TO theo mã
  Future<TOModel?> getTO(String maTO) async {
    final db = await instance.database;

    final result = await db.query(
      'transfer_orders',
      where: 'maTO = ?',
      whereArgs: [maTO],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return TOModel(
      maTO: row['maTO'] as String,
      danhSachGoiHang: (row['danhSachGoiHang'] as String).split(','),
      diaDiemGiaoHang: row['diaDiemGiaoHang'] as String,
      trangThai: row['trangThai'] as String,
      totalWeight: (row['totalWeight'] as num?)?.toDouble() ?? 0.0,
      ngayTao: DateTime.parse(row['ngayTao'] as String),
    );
  }

  /// Lấy tất cả TO
  Future<List<TOModel>> getAllTOs() async {
    final db = await instance.database;

    final result = await db.query('transfer_orders');

    return result
        .map((row) => TOModel(
              maTO: row['maTO'] as String,
              danhSachGoiHang: (row['danhSachGoiHang'] as String).split(','),
              diaDiemGiaoHang: row['diaDiemGiaoHang'] as String,
              trangThai: row['trangThai'] as String,
              totalWeight: (row['totalWeight'] as num?)?.toDouble() ?? 0.0,
              ngayTao: DateTime.parse(row['ngayTao'] as String),
            ))
        .toList();
  }

  /// Cập nhật TO
  Future<void> updateTO(TOModel to) async {
    final db = await instance.database;

    await db.update(
      'transfer_orders',
      {
        'danhSachGoiHang': to.danhSachGoiHang.join(','),
        'diaDiemGiaoHang': to.diaDiemGiaoHang,
        'trangThai': to.trangThai,
        'totalWeight': to.totalWeight,
        'ngayTao': to.ngayTao.toIso8601String(),
      },
      where: 'maTO = ?',
      whereArgs: [to.maTO],
    );

    print('✓ Cập nhật TO: ${to.maTO}');
  }

  /// Xóa TO
  Future<void> deleteTO(String maTO) async {
    final db = await instance.database;

    await db.delete(
      'transfer_orders',
      where: 'maTO = ?',
      whereArgs: [maTO],
    );

    print('✓ Xóa TO: $maTO');
  }

  /// Tìm kiếm TO theo từ khóa
  Future<List<TOModel>> searchTOs(String keyword) async {
    final db = await instance.database;

    final result = await db.query(
      'transfer_orders',
      where: 'maTO LIKE ?',
      whereArgs: ['%${keyword.toUpperCase()}%'],
    );

    return result
        .map((row) => TOModel(
              maTO: row['maTO'] as String,
              danhSachGoiHang: (row['danhSachGoiHang'] as String).split(','),
              diaDiemGiaoHang: row['diaDiemGiaoHang'] as String,
              trangThai: row['trangThai'] as String,
              totalWeight: (row['totalWeight'] as num?)?.toDouble() ?? 0.0,
              ngayTao: DateTime.parse(row['ngayTao'] as String),
            ))
        .toList();
  }

  /// Đếm số lượng TO
  Future<int> countTOs() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM transfer_orders');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Xóa hết dữ liệu (tuỳ chọn)
  Future<void> deleteAllTOs() async {
    final db = await instance.database;
    await db.delete('transfer_orders');
    print('✓ Xóa hết tất cả TO');
  }
}
