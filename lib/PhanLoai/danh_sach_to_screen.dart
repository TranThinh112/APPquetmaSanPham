/// =============================================================
/// File: danh_sach_to_screen.dart (CẬP NHẬP)
/// Mô tả: Màn hình "Created TO" - Danh sách bao hàng đã tạo.
///
/// Thay đổi mới:
///   - Lấy dữ liệu từ TODatabase (SQLite) thay vì TOStorage
///   - Thêm column KG (trọng lượng)
///   - Hiển thị: Mã TO | Số lượng | Địa điểm | Trạng thái | Trọng lượng (KG)
/// =============================================================
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/to_model.dart';
import '../data/to_database.dart';
import 'tao_bao_hang_screen.dart';

class CreatedTO extends StatefulWidget {
  const CreatedTO({super.key});

  @override
  State<CreatedTO> createState() => _CreatedTOState();
}

class _CreatedTOState extends State<CreatedTO> {
  final TextEditingController searchController = TextEditingController();
  List<TOModel> filteredList = [];
  bool _isDeleteMode = false;
  final Set<String> _selectedTOs = {};

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  /// Tự động refresh khi quay lại màn hình
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshList();
  }

  Future<void> _refreshList() async {
    try {
      final allTOs = await TODatabase.instance.getAllTOs();
      setState(() {
        if (searchController.text.isEmpty) {
          filteredList = allTOs;
        } else {
          filteredList = _searchTOs(allTOs, searchController.text);
        }
      });
    } catch (e) {
      debugPrint('Error refreshing list: $e');
    }
  }

  Future<void> _search(String keyword) async {
    try {
      final allTOs = await TODatabase.instance.getAllTOs();
      setState(() {
        filteredList = _searchTOs(allTOs, keyword);
      });
    } catch (e) {
      debugPrint('Error searching: $e');
    }
  }

  List<TOModel> _searchTOs(List<TOModel> list, String keyword) {
    if (keyword.isEmpty) return list;
    final upper = keyword.toUpperCase();
    return list
        .where((to) => to.maTO.toUpperCase().contains(upper))
        .toList();
  }

  /// Mở màn hình CreateTO ở chế độ chỉnh sửa
  void _editTO(TOModel to) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTO(editTO: to),
      ),
    );
    _refreshList();
  }

  Future<void> _scanToSearch() async {
    final scanController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      returnImage: false,
      formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Quét mã bao hàng'),
          content: SizedBox(
            width: 280,
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: scanController,
                onDetect: (capture) {
                  if (capture.barcodes.isEmpty) return;
                  final code = capture.barcodes.first.rawValue?.trim() ?? '';
                  if (code.isNotEmpty) {
                    searchController.text = code.toUpperCase();
                    _search(code.toUpperCase());
                    scanController.dispose();
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                scanController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header cam với logo SPX ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          label: const Text(
                            'Quay lại',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isDeleteMode = !_isDeleteMode;
                              _selectedTOs.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 50,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SPX Express',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Thanh tìm kiếm + nút quét ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: 'Tìm mã bao hàng...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.orange[600]),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.orange[600]!, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: _scanToSearch,
                      icon: const Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bảng dữ liệu (kéo ngang được) ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                        border: TableBorder.all(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        columnWidths: {
                          if (_isDeleteMode) 0: const FixedColumnWidth(40),
                          (_isDeleteMode ? 1 : 0): const FixedColumnWidth(130),
                          (_isDeleteMode ? 2 : 1): const FixedColumnWidth(80),
                          (_isDeleteMode ? 3 : 2): const FixedColumnWidth(150),
                          (_isDeleteMode ? 4 : 3): const FixedColumnWidth(100),
                          (_isDeleteMode ? 5 : 4): const FixedColumnWidth(80),
                          (_isDeleteMode ? 6 : 5): const FixedColumnWidth(50),
                        },
                        children: [
                          // Header row
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                            ),
                            children: [
                              if (_isDeleteMode)
                                const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(width: 20),
                                ),
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Mã TO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Số lượng',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Địa điểm\ngiao hàng',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Trạng thái',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'KG',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Sửa',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          // Data rows
                          ...filteredList.map((to) {
                            final isPacked = to.trangThai == 'Packed';
                            return TableRow(
                              children: [
                                if (_isDeleteMode)
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (_selectedTOs.contains(to.maTO)) {
                                              _selectedTOs.remove(to.maTO);
                                            } else {
                                              _selectedTOs.add(to.maTO);
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        splashColor: Colors.blue.withOpacity(0.3),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _selectedTOs.contains(to.maTO)
                                                  ? Colors.red
                                                  : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                            color: _selectedTOs.contains(to.maTO)
                                                ? Colors.red
                                                : Colors.transparent,
                                          ),
                                          child: _selectedTOs.contains(to.maTO)
                                              ? const Icon(Icons.check,
                                                  size: 14, color: Colors.white)
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    to.maTO,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    '${to.soLuongDonHang}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    to.diaDiemGiaoHang.isEmpty
                                        ? '—'
                                        : to.diaDiemGiaoHang,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPacked
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      to.trangThai,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    '${to.totalWeight.toStringAsFixed(1)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                // Cột Sửa (chỉ hiện icon khi Packing)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _editTO(to),
                                      borderRadius: BorderRadius.circular(20),
                                      splashColor: Colors.orange.withOpacity(0.3),
                                      child: Icon(Icons.edit,
                                          color: Colors.orange[600],
                                          size: 22),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                ),
            ),

            // ── Nút xác nhận xóa + hủy (chỉ hiện khi ở chế độ xóa) ──
            if (_isDeleteMode)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _selectedTOs.isEmpty
                            ? null
                            : () async {
                                for (final maTO in _selectedTOs) {
                                  await TODatabase.instance.deleteTO(maTO);
                                }
                                setState(() {
                                  _selectedTOs.clear();
                                  _isDeleteMode = false;
                                });
                                _refreshList();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 6,
                          shadowColor: Colors.red.withOpacity(0.5),
                        ),
                        child: Text(
                          'Xác nhận xóa (${_selectedTOs.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isDeleteMode = false;
                            _selectedTOs.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
