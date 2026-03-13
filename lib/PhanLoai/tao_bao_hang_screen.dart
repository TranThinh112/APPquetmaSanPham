/// =============================================================
/// File: tao_bao_hang_screen.dart
/// Mô tả: Màn hình "Create TO" - Tạo bao hàng lớn.
///
/// Chức năng:
///   - Tự động sinh mã bao hàng (TO ID) dạng TO + YY + MM + 4 ký tự ngẫu nhiên
///   - Quét mã barcode gói hàng nhỏ (SPXVN06 + 10 chữ số)
///   - Hỗ trợ nhập tay mã gói hàng
///   - Hỗ trợ quét từ ảnh trong gallery
///   - Giới hạn tối đa 15 gói hàng nhỏ / 1 bao hàng
///   - Kiểm tra trùng mã, kiểm tra định dạng hợp lệ
///   - Hiển thị danh sách gói hàng đã quét (có thể xóa từng mã)
///   - Nút Complete: lưu bao hàng vào bộ nhớ (TOStorage) và quay lại
///
/// Luồng: Camera quét → validate → thêm vào list → Complete → đóng bao
/// =============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/to_model.dart';
import '../data/to_storage.dart';
import '../data/order_dtb.dart';

class ScannedItem {
  final String code;
  final DateTime timestamp;

  ScannedItem({required this.code, required this.timestamp});
}

class CreateTO extends StatefulWidget {
  /// Nếu truyền editTO vào → chế độ chỉnh sửa (load dữ liệu cũ)
  final TOModel? editTO;
  const CreateTO({super.key, this.editTO});

  @override
  State<CreateTO> createState() => _CreateTOState();
}

class _CreateTOState extends State<CreateTO>
    with SingleTickerProviderStateMixin {
  double TongKhoiLuong = 0;
  String station = "";
  String result = "";
  String type = "";
  final List<ScannedItem> scannedCodes = [];
  late String toId;
  String _originalStatus = 'Packing';
  late AnimationController animationController;
  late Animation<double> animation;

  // Scroll + input animation helpers
  final ScrollController listScrollController = ScrollController();
  final FocusNode inputFocus = FocusNode();
  String animatedText = "";

  String? centerMessage;
  Color? centerMessageColor;
  Timer? _messageTimer;

  final TextEditingController inputController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final AudioPlayer player = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    facing: CameraFacing.back,
    returnImage: false,
    formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13, BarcodeFormat.code128],
  );

  /// Sinh mã TO ID: TO2603 + 4 ký tự ngẫu nhiên (chữ + số)
  /// Ví dụ: TO2603AB1X
  String _generateTOId() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final rand = String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
    return 'TO2603$rand';
  }

  /// Cập nhật TO trong storage mỗi khi có thay đổi (quét mã, xóa mã, đổi địa chỉ)
  void _updateTOInStorage() {
    TOStorage.instance.update(
      toId,
      TOModel(
        maTO: toId,
        danhSachGoiHang: scannedCodes.map((item) => item.code).toList(),
        diaDiemGiaoHang: addressController.text.trim(),
        trangThai: _originalStatus,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final editTO = widget.editTO;
    if (editTO != null) {
      // Chế độ chỉnh sửa → load dữ liệu cũ
      toId = editTO.maTO;
      _originalStatus = editTO.trangThai;
      scannedCodes.addAll(editTO.danhSachGoiHang.map((code) => ScannedItem(code: code, timestamp: DateTime.now())));
      addressController.text = editTO.diaDiemGiaoHang;
    } else {
      // Chế độ tạo mới → sinh TO ID mới + lưu vào storage
      toId = _generateTOId();
      TOStorage.instance.add(
        TOModel(maTO: toId, danhSachGoiHang: [], trangThai: 'Packing'),
      );
    }

    // Lắng nghe thay đổi địa chỉ → cập nhật TO
    addressController.addListener(_updateTOInStorage);

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    animation = Tween<double>(begin: 0, end: 1).animate(animationController);
  }

  /// Kiểm tra định dạng mã gói hàng nhỏ: SPXVN06 + 10 chữ số
  /// Ví dụ hợp lệ: SPXVN061234567890
  bool isValidSPX(String code) {
    final regex = RegExp(r'^SPXVN06\d{10}$', caseSensitive: false);
    return regex.hasMatch(code.trim());
  }

  /// Animation: hiển thị dần mã quét vào input để người dùng thấy
  Future<void> _animateScanText(String code) async {
    if (!mounted) return;

    inputFocus.requestFocus();

    for (int i = 0; i < code.length; i += 2) {
      final end = (i + 2 < code.length) ? i + 2 : code.length;
      inputController.text = code.substring(0, end);
      await Future.delayed(const Duration(milliseconds: 5));
    }

    await Future.delayed(const Duration(milliseconds: 80));

    // Bôi chọn toàn bộ để dễ copy / chỉnh sửa
    inputController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: code.length,
    );

    setState(() {
      animatedText = code;
    });
  }

  bool isProcessing = false;

  void _showCenterMessage(String text, Color color, {Duration duration = const Duration(milliseconds: 900)}) {
    _messageTimer?.cancel();
    setState(() {
      centerMessage = text;
      centerMessageColor = color;
    });
    _messageTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        centerMessage = null;
      });
    });
  }

  /// Xử lý mã được quét hoặc nhập tay:
  /// 1. Kiểm tra đã đạt tối đa 15 gói hàng chưa
  /// 2. Kiểm tra mã đã quét trước đó (trùng lặp)
  /// 3. Kiểm tra định dạng SPXVN06 hợp lệ
  /// 4. Nếu hợp lệ → thêm vào danh sách + phát tiếng beep
  Future<void> _processCode(String code, String codeType) async {
    code = code.trim().toUpperCase();

    if (code.isEmpty) return;

    // Kiểm tra đã đạt tối đa 15 gói hàng
    if (scannedCodes.length >= TOModel.maxGoiHang) {
      _showCenterMessage('Đã đạt tối đa 15 gói hàng!', Colors.red);
      await player.stop();
      await player.play(AssetSource('error.mp3'));
      return;
    }

    // Kiểm tra mã đã quét trước đó
    if (scannedCodes.any((item) => item.code == code)) {
      _showCenterMessage('Error! Already scanned', Colors.red);
      await player.stop();
      await player.play(AssetSource('error.mp3'));
      return;
    }

    if (!isValidSPX(code)) {
      _showCenterMessage('Error! Scan Again', Colors.red);
      await player.stop();
      await player.play(AssetSource('error.mp3'));
      return;
    }
    final order = await OrderDatabase.instance.getOrder(code);

    if (order != null) {
      setState(() {
        station = order['station'];
        double weight =order['weight'];
        TongKhoiLuong += weight;
      });
    }

    // Hiệu ứng show mã vào ô input giống quét
    await _animateScanText(code);

    setState(() {
      result = code;
      type = codeType;
      // Thêm mã mới lên trên cùng
      scannedCodes.insert(0, ScannedItem(code: code, timestamp: DateTime.now()));
    });

    // Cuộn lên đầu (mã mới) nếu có thể
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (listScrollController.hasClients) {
        listScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    // Cập nhật TO trong storage ngay sau khi thêm mã
    _updateTOInStorage();

    await player.stop();
    await player.play(AssetSource('beep.mp3'));
    _showCenterMessage('Success Added', Colors.green);
  }

  /// Callback khi camera phát hiện barcode
  /// Chống quét liên tục bằng cờ isProcessing + delay 900ms
  void _handleBarcode(BarcodeCapture capture) async {
    if (isProcessing) return;

    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final newValue = barcode.rawValue?.trim() ?? "";

    if (newValue.isEmpty) return;

    isProcessing = true;

    await _processCode(newValue, barcode.format.name);

    await Future.delayed(const Duration(milliseconds: 900));

    isProcessing = false;
  }

  /// Quét mã từ ảnh trong gallery (đọc mã barcode từ file ảnh)
  Future<void> _scanFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final BarcodeCapture? capture = await controller.analyzeImage(image.path);

    if (capture != null && capture.barcodes.isNotEmpty) {
      final barcode = capture.barcodes.first;
      final newValue = barcode.rawValue?.trim() ?? "";

      if (newValue.isNotEmpty) {
        isProcessing = true;
        await _processCode(newValue, barcode.format.name);
        isProcessing = false;
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã hợp lệ trong ảnh.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    await player.stop();
    await player.play(AssetSource('error.mp3'));
  }

  @override
  void dispose() {
    addressController.removeListener(_updateTOInStorage);
    controller.dispose();
    animationController.dispose();
    listScrollController.dispose();
    inputFocus.dispose();
    inputController.dispose();
    addressController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header cam ──
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
                        'Create TO',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.photo_library, color: Colors.orange[800]),
                        onPressed: _scanFromGallery,
                      ),
                    ],
                  ),
                ),

                // ── Nội dung chính (scrollable) ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TO ID: $toId',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Số lượng: ${scannedCodes.length}/${TOModel.maxGoiHang}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Station: $station',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'khối lượng: ${TongKhoiLuong.toStringAsFixed(2)} kg',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ── Dữ liệu input cùng hàng ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Dữ liệu input:',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: inputController,
                                focusNode: inputFocus,
                                decoration: InputDecoration(
                                  hintText: 'Nhập dữ liệu...',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.orange[600]!,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            ElevatedButton(
                              onPressed: () async {
                                final text = inputController.text.trim();
                                if (text.isNotEmpty) {
                                  FocusScope.of(context).unfocus();
                                  isProcessing = true;
                                  await _processCode(text, 'Manual Input');
                                  inputController.clear();
                                  isProcessing = false;
                                } else {
                                  _showCenterMessage('Vui lòng nhập mã vào ô trống.', Colors.orange);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Confirm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Camera preview (khung cam) ──
                        Center(
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orange[600]!,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  MobileScanner(
                                    controller: controller,
                                    onDetect: _handleBarcode,
                                  ),
                                  AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, child) {
                                      return Positioned(
                                        top: animation.value * 248,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 3,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange.withValues(alpha: 0),
                                                Colors.orange,
                                                Colors.orange.withValues(alpha: 0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 60,
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'Quét Mã',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Dữ liệu quét ──
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Container(
                              height: 150,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dữ liệu quét:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: scannedCodes.isEmpty
                                        ? Center(
                                            child: Text(
                                              'Đưa camera vào mã để quét...',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            controller: listScrollController,
                                            itemCount: scannedCodes.length,
                                            itemBuilder: (context, index) {
                                              final item = scannedCodes[index];
                                              final timeStr = DateFormat('HH:mm:ss').format(item.timestamp);
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                                child: Row(
                                                  children: [
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: SelectableText(
                                                        '${item.code} - $timeStr',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          scannedCodes.removeAt(index);
                                                        });
                                                        _updateTOInStorage();
                                                      },
                                                      child: Icon(
                                                        Icons.close,
                                                        size: 18,
                                                        color: Colors.red[400],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Nút Complete ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (scannedCodes.isEmpty) {
                                _showCenterMessage('Chưa quét gói hàng nào!', Colors.orange);
                                return;
                              }
                              TOStorage.instance.update(
                                toId,
                                TOModel(
                                  maTO: toId,
                                  danhSachGoiHang: List.from(scannedCodes),
                                  diaDiemGiaoHang: addressController.text.trim(),
                                  trangThai: 'Packed',
                                ),
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              shadowColor: Colors.orange.withValues(alpha: 0.4),
                            ),
                            child: const Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: centerMessage == null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: centerMessage == null ? 0.0 : 1.0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: (centerMessageColor ?? Colors.black87).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        centerMessage ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
