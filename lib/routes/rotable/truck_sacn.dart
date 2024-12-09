import '../../index.dart';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class TruckScan extends StatefulWidget{
  TruckScan({Key? key}) : super(key: key);
  @override
  _TruckScan createState() => _TruckScan();
}

class _TruckScan extends State<TruckScan>{
  Barcode? result;
  QRViewController? controller;
  final GlobalKey mqrKey = GlobalKey(debugLabel: 'MQR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 5, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                        '码类型: ${describeEnum(result!.format)}   内容: ${result!.code}')
                  else
                    const Text('Scan a code'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.toggleFlash();
                            setState(() {});
                          },
                          style: ButtonStyle(
                            // 圆角
                            shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            // 背景透明
                            // backgroundColor: MaterialStateProperty.all(Colors.transparent),
                            // shadowColor: MaterialStateProperty.all(Colors.transparent)
                          ),
                          child: FutureBuilder(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              if(snapshot.data == false){
                                return Icon(Icons.flash_off);
                              }else{
                                return Icon(Icons.flash_on);
                              }
                              // return Text('Flash: ${snapshot.data}');
                            },
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.flipCamera();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  return Icon(Icons.change_circle_outlined);
                                  // return Text(
                                  //     'Camera facing ${describeEnum(snapshot.data!)}');
                                } else {
                                  return const Text('loading');
                                }
                              },
                            )),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: mqrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });
      // try{
      //   // 暂停摄像头避免同一二维码多次生成页面
      //   controller.pauseCamera();
      //   var reveal2 = await RotableApi().queryRotable(queryParametrs: {'id':result?.code});
      //   if(reveal2.code == 200){
      //     Navigator.of(context).pop(reveal2);
      //   }
      // }on DioException catch(e){
      //   // 错误警告
      //   if(e.response?.statusCode == 500) {
      //     showToast("二维码数据错误");
      //     controller.resumeCamera();
      //   }else{
      //     showToast(e.toString());
      //     controller.resumeCamera();
      //   }
      // }finally{
      //   controller.resumeCamera();
      // }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}