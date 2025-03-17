import '../index.dart';
import 'dart:developer';

import 'package:flutter/foundation.dart';


class MainScanner extends StatefulWidget{
  const MainScanner({Key? key}) : super(key: key);
  @override
  State createState() => _MainScanner();
}

class _MainScanner extends State<MainScanner>{
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
                                return const Icon(Icons.flash_off);
                              }else{
                                return const Icon(Icons.flash_on);
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
                                  return const Icon(Icons.change_circle_outlined);
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
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   crossAxisAlignment: CrossAxisAlignment.center,
                  //   children: <Widget>[
                  //     Container(
                  //       margin: const EdgeInsets.all(8),
                  //       child: ElevatedButton(
                  //         onPressed: () async {
                  //           await controller?.pauseCamera();
                  //         },
                  //         child: const Text('pause',
                  //             style: TextStyle(fontSize: 20)),
                  //       ),
                  //     ),
                  //     Container(
                  //       margin: const EdgeInsets.all(8),
                  //       child: ElevatedButton(
                  //         onPressed: () async {
                  //           await controller?.resumeCamera();
                  //         },
                  //         child: const Text('resume',
                  //             style: TextStyle(fontSize: 20)),
                  //       ),
                  //     )
                  //   ],
                  // ),
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

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });
      // if(result!.code!.contains('{')){
      //   Navigator.of(context).pushNamed('showSMRO',arguments:SMRORotable.fromJson(json.decode(result!.code??"")));
      // }else{
        // try{
        //   // 暂停摄像头避免同一二维码多次生成页面
        //   controller.pauseCamera();
        //   var reveal = await SearchApi().qrSearch(queryParametrs:{'qrId':result?.code});
        //   print(reveal.code);
        //   if(reveal.code == 500){
        //     var reveal2 = await RotableApi().queryRotable(queryParametrs: {'id':result?.code});
        //     if(reveal2.data == null){
        //       showToast('库中未查询到二维码数据');
        //       controller.resumeCamera();
        //     }else{
        //       // 周转件
        //       Navigator.of(context).pushNamed('QRsearchPage',arguments: QRSearchMsg(2, reveal2)).then((value) => {
        //         controller.resumeCamera()
        //       });
        //     }
        //   }else if(reveal.data != null){
        //     // 一般件
        //     Navigator.of(context).pushNamed('QRsearchPage',arguments: QRSearchMsg(1, reveal)).then((value) => {
        //       controller.resumeCamera()
        //     });
        //   }
        // }on DioException catch(e){
        //   // 错误警告 showToast
        //   if(e.response?.statusCode == 500) {
        //     showToast("二维码数据错误");
        //     controller.resumeCamera();
        //   }else{
        //     showToast(e.toString());
        //     controller.resumeCamera();
        //   }
        // }finally{
        // }
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