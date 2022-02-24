import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRViewPage extends StatefulWidget {
  const QRViewPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewPageState();
}

class _QRViewPageState extends State<QRViewPage> {
  bool _isOpenDialogue = false;
  final MobileScannerController _controller = MobileScannerController(
    torchEnabled: false,
    facing: CameraFacing.back,
  );
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: _buildQrView()
          ),
          Positioned(
            top: screenSize.height * 0.05,
            right: 15,
            child: _closeQRScannerButton(context),
          ),
          Positioned(
            top: screenSize.height * 0.05,
            left: 15,
            child: _flashButton(),
          ),
          Positioned(
            bottom: screenSize.height * 0.04,
            child: Container(
              margin: const EdgeInsets.only(top: 80, left: 15, right: 15),
              child: const Text(
                'Move the camera to QR code to scan',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView() {
    return MobileScanner(
        controller: _controller,
        fit: BoxFit.fill,
        onDetect: (barcode, args) {
          if (!_isOpenDialogue) {
            _isOpenDialogue = true;
            _saveLocalData(barcode.rawValue);
            Future.delayed(const Duration(milliseconds: 500), () {
              _displayDeleteDialog(barcode.rawValue);
            });
          }
        });
  }

  Widget _closeQRScannerButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Icon(Icons.clear_rounded),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        primary: Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _flashButton() {
    return ElevatedButton(
      child: ValueListenableBuilder(
        valueListenable: _controller.torchState,
        builder: (context, state, child) {
          switch (state as TorchState) {
            case TorchState.off:
              return const Icon(Icons.flash_off, color: Colors.grey);
            case TorchState.on:
              return const Icon(Icons.flash_on, color: Colors.amberAccent);
          }
        },
      ),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        primary: Colors.white.withOpacity(0.3),
      ),
      onPressed: () => _controller.toggleTorch(),
    );
  }

  Future<void> _saveLocalData(String barcode) async {
    final SharedPreferences prefs = await _prefs;
    final barcodeList = prefs.getStringList("barcode_list_key") ?? [];
    barcodeList.add(barcode);
    prefs.setStringList('barcode_list_key', barcodeList);
  }

  Future<void> _displayDeleteDialog(String data) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.3),
            title: Center(
                child: Text(
              data,
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
            )),
            actions: <Widget>[
              TextButton(
                child: const Text('EXIT', style: TextStyle(color: Colors.white),),
                onPressed: () {
                  setState(() {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  });
                },
              ),
              TextButton(
                child: const Text('NEXT', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  setState(() {
                    _isOpenDialogue = false;
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }
}
