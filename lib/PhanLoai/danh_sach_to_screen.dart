/// =============================================================
/// File: danh_sach_to_screen.dart
/// Mô tả: Màn hình "Created TO" - Danh sách bao hàng đã tạo.
///
/// Chức năng:
///   - Hiển thị bảng danh sách các bao hàng đã đóng gồm:
///     + Mã bao hàng (TO ID)
///     + Số lượng đơn hàng trong bao
///     + Địa điểm giao hàng
///   - Thanh tìm kiếm mã bao hàng (search text)
///   - Nút quét QR để tìm kiếm nhanh bao hàng
///
/// Dữ liệu: đọc từ TOStorage (singleton in-memory)
/// =============================================================
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/to_model.dart';
import '../data/to_storage.dart';
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

  void _refreshList() {
    setState(() {
      if (searchController.text.isEmpty) {
        filteredList = TOStorage.instance.all;
      } else {
        filteredList = TOStorage.instance.search(searchController.text);
      }
    });
  }

  void _search(String keyword) {
    setState(() {
      filteredList = TOStorage.instance.search(keyword);
    });
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
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[300]!, Colors.orange[100]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.orange[800]),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Table TO',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.orange[800]),
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
                          (_isDeleteMode ? 5 : 4): const FixedColumnWidth(50),
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
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (_selectedTOs.contains(to.maTO)) {
                                            _selectedTOs.remove(to.maTO);
                                          } else {
                                            _selectedTOs.add(to.maTO);
                                          }
                                        });
                                      },
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
                                // Cột Sửa (chỉ hiện icon khi Packing)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: GestureDetector(
                                          onTap: () => _editTO(to),
                                          child: Icon(Icons.edit,
                                              color: Colors.orange[700],
                                              size: 22),
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
                            : () {
                                for (final maTO in _selectedTOs) {
                                  TOStorage.instance.remove(maTO);
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
