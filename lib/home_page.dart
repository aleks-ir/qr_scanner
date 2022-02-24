import 'dart:developer';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:qr_scanner/qr_view_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('QR-Scanner'),
      ),
      body: const Center(
        child: HomeWidget(),
      ),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  List<String> _barcodeList = [];
  bool _isRemoveMode = false;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    initializePreference().whenComplete(() {
      setState(() {});
    });
  }

  Future<void> initializePreference() async {
    final SharedPreferences prefs = await _prefs;
    _barcodeList = prefs.getStringList("barcode_list_key") ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: _barcodeList.isEmpty
                ? const Center(child: Text('No Items'))
                : _isRemoveMode
                    ? _getDismissibleListView()
                    : _getGestureDetectorListView()),
        Container(
          padding: const EdgeInsets.only(bottom: 50, top: 40),
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              FloatingActionButton(
                heroTag: "btn_delete",
                onPressed: () {
                  setState(() {
                    _isRemoveMode = _isRemoveMode ? false : true;
                  });
                  //_displayDeleteDialog();
                },
                child: Icon(
                  Icons.delete_sweep,
                  color: _isRemoveMode ? Colors.amberAccent : Colors.white,
                ),
              ),
              const Spacer(),
              FloatingActionButton.extended(
                heroTag: "btn_scan",
                onPressed: () {
                  _navigateAndDisplayQRViewPage(context);
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan'),
              ),
              const Spacer(),
              FloatingActionButton(
                heroTag: "btn_save",
                onPressed: () {
                  _saveData(context);
                },
                child: const Icon(Icons.save_outlined),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateAndDisplayQRViewPage(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRViewPage()),
    ).whenComplete(() => initializePreference().whenComplete(() {
          setState(() {});
        }));
  }

  Widget _getDismissibleListView() {
    return ListView.separated(
      itemCount: _barcodeList.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        return Dismissible(
          key: Key(UniqueKey().toString()),
          onDismissed: (direction) {
            _deleteItem(index);
          },
          child: ListTile(
            title: Text(_barcodeList[index]),
          ),
        );
      },
    );
  }

  Widget _getGestureDetectorListView() {
    return ListView.separated(
      itemCount: _barcodeList.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onLongPress: () {
            _copyToClipboard(_barcodeList[index]);
          },
          child: ListTile(
            title: Text(_barcodeList[index]),
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(int index) async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      _barcodeList.removeAt(index);
    });
    prefs.setStringList("barcode_list_key", _barcodeList);
    _displaySnackBar("Successfully deleted!");
  }

  _saveData(BuildContext context) async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final excel.Workbook workbook = excel.Workbook();
      final excel.Worksheet sheet = workbook.worksheets[0];
      for (var i = 0; i < _barcodeList.length; i++) {
        sheet.getRangeByIndex(i + 1, 1).setText(_barcodeList[i]);
      }
      final List<int> sheets = workbook.saveAsStream();
      workbook.dispose();

      Uint8List data = Uint8List.fromList(sheets);
      MimeType type = MimeType.OTHER;
      String path = await FileSaver.instance
          .saveAs("scan_" + _getCurrentDate(), data, "xlsx", type);
      log(path);

      _displaySnackBar("Successfully saved!");
    }
  }

  _getCurrentDate() {
    return DateFormat('yyyy-MM-dd_kk-mm-ss').format(DateTime.now());
  }

  _displaySnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
          SnackBar(padding: const EdgeInsets.all(10), content: Text(message)));
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _displaySnackBar("Successfully copied!");
  }
}
