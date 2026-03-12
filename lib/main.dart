import 'package:flutter/material.dart';
import 'spx_express_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget buildCard(Color color, IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.black54),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      body: SafeArea(
        child: Stack(
          children: [
            // Grid menu - centered on full screen
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    buildCard(
                      Colors.blue[100]!,
                      Icons.camera_alt,
                      "Quét QR",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SpxExpressScreen(),
                          ),
                        );
                      },
                    ),
                    buildCard(
                      Colors.green[100]!,
                      Icons.search,
                      "Tra cứu đơn hàng",
                    ),
                    buildCard(
                      Colors.purple[100]!,
                      Icons.folder,
                      "Quản lý đơn hàng",
                    ),
                    buildCard(
                      Colors.yellow[100]!,
                      Icons.settings,
                      "Cài đặt",
                    ),
                  ],
                ),
              ),
            ),

            // Header - overlay on top
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.orange[700],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 55,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'SPX Express',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
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
