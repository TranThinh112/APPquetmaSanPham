import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';

class ScanTO extends StatefulWidget {
  const ScanTO({super.key});

  @override
  State<ScanTO> createState() => _ScanTOState();
}

class _ScanTOState extends State<ScanTO>
    with SingleTickerProviderStateMixin {
  String result = "";
  String type = "";

  late AnimationController animationController;
  late Animation<double> animation;

  final TextEditingController inputController = TextEditingController();
  final AudioPlayer player = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    facing: CameraFacing.back,
    returnImage: false,
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.code128,
    ],
  );

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    animation = Tween<double>(begin: 0, end: 1).animate(animationController);
  }
  //kiem tra dinh dang ma 
  bool isValidTO(String code) {
    final regex = RegExp(r'^TO2603[A-Z0-9]{4}$', caseSensitive: false);
    return regex.hasMatch(code.trim());
  }
    bool isProcessing = false;

  Future<void> _processCode(String code, String codeType) async {
  //dong bo chu hoa
  
    code = code.trim().toUpperCase();
    if (code.isEmpty) return;

    if (code == result) {
      await player.stop();
      await player.play(AssetSource('error.mp3'));
      return;
    }

  // Kiểm tra cấu trúc SPXVN06XXXXXXXX
  if (!isValidTO(code)) {
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);

      messenger.clearMaterialBanners();

      messenger.showMaterialBanner(
        const MaterialBanner(
          content: Text(
            "Error! Scan Again",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
          leading: Icon(Icons.error, color: Colors.white),
          actions: [SizedBox()],
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        messenger.clearMaterialBanners();
      });
    }

    await player.stop();
    await player.play(AssetSource('error.mp3'));
    return;
  }

  setState(() {
    result = code;
    type = codeType;
  });

  await player.stop();
  await player.play(AssetSource('beep.mp3'));
}


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
    controller.dispose();
    animationController.dispose();
    inputController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                    // ── Dữ liệu input ──
                    const Text(
                      'Dữ liệu input:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: inputController,
                            decoration: InputDecoration(
                              hintText: 'Nhập dữ liệu...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
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
                                borderSide: BorderSide(
                                    color: Colors.orange[600]!, width: 2),
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
                              FocusScope.of(context).unfocus(); // Ẩn bàn phím
                              isProcessing = true;
                              await _processCode(text, 'Manual Input');
                              inputController.clear();
                              isProcessing = false;
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng nhập mã vào ô trống.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
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
                              color: Colors.orange.withOpacity(0.15),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Live camera
                              MobileScanner(
                                controller: controller,
                                onDetect: _handleBarcode,
                              ),

                              // Scan line animation
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
                                            Colors.orange.withOpacity(0),
                                            Colors.orange,
                                            Colors.orange.withOpacity(0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Icon camera khi chưa có camera (fallback)
                              Center(
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Label "Quét Mã"
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
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
                          Text(
                            result.isEmpty
                                ? 'Đưa camera vào mã để quét...'
                                : result,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: result.isEmpty
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              color: result.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ── Nút Complete ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: xử lý complete
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor: Colors.orange.withOpacity(0.4),
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
      ),
    );
  }
}