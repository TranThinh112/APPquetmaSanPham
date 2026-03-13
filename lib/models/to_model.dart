/// =============================================================
/// File: to_model.dart
/// Mô tả: Model dữ liệu cho bao hàng (Transfer Order - TO).
///
/// Thuộc tính:
///   - maTO           : Mã TO (VD: TO2603AB1X) - định dạng TO2603 + 4 ký tự ngẫu nhiên
///   - danhSachGoiHang : Danh sách mã gói hàng nhỏ trong bao
///   - diaDiemGiaoHang : Địa điểm giao hàng
///   - trangThai      : Trạng thái bao hàng (Packing / Packed)
///   - ngayTao        : Ngày tạo bao hàng
///   - soLuongDonHang : Getter - số gói hàng trong bao
///   - maxGoiHang     : Hằng số - tối đa 15 gói hàng / bao
/// =============================================================
class TOModel {
  final String maTO;              // Mã TO (VD: TO2603AB1X)
  final List<String> danhSachGoiHang; // Danh sách mã gói hàng nhỏ
  final String diaDiemGiaoHang;   // Địa điểm giao hàng
  final String trangThai;         // Trạng thái: 'Packing' hoặc 'Packed'
  final DateTime ngayTao;

  TOModel({
    required this.maTO,
    required this.danhSachGoiHang,
    this.diaDiemGiaoHang = '',
    this.trangThai = 'Packed',
    DateTime? ngayTao,
  }) : ngayTao = ngayTao ?? DateTime.now();

  int get soLuongDonHang => danhSachGoiHang.length;

  static const int maxGoiHang = 15;
}
