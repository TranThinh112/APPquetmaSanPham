/// =============================================================
/// File: phan_loai_screen.dart
/// Mô tả: Màn hình menu "Phân Loại" - điều hướng đến 3 chức năng:
///        1. Create TO  → Tạo bao hàng mới (đóng bao)
///        2. Scan TO    → Quét mã TO để kiểm tra
///        3. Created TO → Xem danh sách bao hàng đã tạo
/// =============================================================
import 'package:flutter/material.dart';
import 'PhanLoai/tao_bao_hang_screen.dart';
import 'PhanLoai/quet_to_screen.dart';
import 'PhanLoai/danh_sach_to_screen.dart';

class PhanLoaiScreen extends StatelessWidget {
  const PhanLoaiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Buttons centered on full screen
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuButton(
                      icon: Icons.add_circle_outline,
                      label: 'Create TO',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateTO(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildMenuButton(
                      icon: Icons.qr_code_scanner,
                      label: 'Scan TO',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScanTO(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildMenuButton(
                      icon: Icons.list_alt,
                      label: 'Table TO',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreatedTO(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Top: header cam bao gồm nút quay lại + logo
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange[700],
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          label: const Text(
                            'Quay lại',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SPX',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'Express',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.orange[700],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
