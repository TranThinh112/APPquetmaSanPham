import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  String result = "";
  String type = "";

  late AnimationController animationController;
  late Animation<double> animation;
  // tieng beep khi scan thanh cong
  final AudioPlayer player = AudioPlayer();
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

    animation = Tween<double>(begin: 0, end: 200).animate(animationController);
  }

  bool isProcessing = false;

  void _handleBarcode(BarcodeCapture capture) async {
    if (isProcessing) return;

    final barcode = capture.barcodes.first;
    final newValue = barcode.rawValue ?? "";

    if (newValue.isEmpty) return;

    isProcessing = true;

    if (newValue == result) {
      await player.stop();
      await player.play(AssetSource('error.mp3'));
    } else {
      setState(() {
        result = newValue;
        type = barcode.format.name;
      });

      await player.stop();
      await player.play(AssetSource('beep.mp3'));
    }

    await Future.delayed(const Duration(milliseconds: 900));

    isProcessing = false;
  }

  @override
  void dispose() {
    controller.dispose();
    animationController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 📸 Camera
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),

          /// 🌑 Overlay đen có lỗ giữa
          CustomPaint(
            size: Size.infinite,
            painter: ScannerOverlayPainter(),
          ),

          /// 🎯 Khung scan + vạch đỏ
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.greenAccent,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Positioned(
                        top: animation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          color: Colors.redAccent,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          /// Nút quay lại
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          /// 📄 Hiển thị kết quả
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 140,
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: result.isEmpty
                    ? const Text(
                        "Đưa camera vào QR hoặc mã vạch 📷",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      )
                    : Text(
                        "Loại: $type\nGiá trị: $result",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.85);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final hole = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
    );

    final path = Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(hole, const Radius.circular(12)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}