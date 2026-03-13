/// =============================================================
/// File: to_storage.dart
/// Mô tả: Singleton lưu trữ danh sách bao hàng trong bộ nhớ.
///
/// Chức năng:
///   - Thêm bao hàng mới (add)
///   - Lấy toàn bộ danh sách (all)
///   - Tìm kiếm theo mã bao hàng (search)
///
/// Lưu ý: Dữ liệu chỉ tồn tại trong phiên chạy app (in-memory).
///        Khi tắt app, dữ liệu sẽ mất.
/// =============================================================
import '../models/to_model.dart';

class TOStorage {
  TOStorage._();
  static final TOStorage instance = TOStorage._();

  final List<TOModel> _list = [];

  List<TOModel> get all => List.unmodifiable(_list);

  void add(TOModel to) {
    _list.add(to);
  }

  /// Cập nhật TO theo mã TO (thay thế TO cũ bằng TO mới)
  void update(String maTO, TOModel newTo) {
    final index = _list.indexWhere((t) => t.maTO == maTO);
    if (index != -1) {
      _list[index] = newTo;
    }
  }

  /// Xóa TO theo mã
  void remove(String maTO) {
    _list.removeWhere((t) => t.maTO == maTO);
  }

  List<TOModel> search(String keyword) {
    if (keyword.isEmpty) return all;
    final upper = keyword.toUpperCase();
    return _list
        .where((to) => to.maTO.toUpperCase().contains(upper))
        .toList();
  }
}
