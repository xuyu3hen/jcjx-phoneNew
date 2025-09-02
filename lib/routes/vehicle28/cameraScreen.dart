// import 'dart:io';
// import 'package:camerawesome/camerawesome_plugin.dart';
// import 'package:camerawesome/pigeon.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';

// typedef MediaCapturedCallback = void Function(XFile file);

// class CameraScreen extends StatefulWidget {
//   final MediaCapturedCallback onMediaCaptured;

//   const CameraScreen({Key? key, required this.onMediaCaptured}) : super(key: key);

//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   bool _isRecording = false;
//   late AwesomeCameraController _cameraController;

//   @override
//   void initState() {
//     super.initState();
//     _cameraController = AwesomeCameraController();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CameraAwesomeBuilder.awesome(
//         onMediaCaptureEvent: (event) {
//           switch ((event.status, event.isPicture, event.isVideo)) {
//             case (MediaCaptureStatus.success, true, false):
//               // 拍照成功
//               event.captureRequest.when(
//                 single: (single) {
//                   if (single.file != null) {
//                     widget.onMediaCaptured(single.file!);
//                   }
//                 },
//                 multiple: (multiple) {
//                   multiple.fileBySensor.forEach((key, value) {
//                     if (value != null) {
//                       widget.onMediaCaptured(value);
//                     }
//                   });
//                 },
//               );
//               break;
//             case (MediaCaptureStatus.success, false, true):
//               // 录像成功
//               event.captureRequest.when(
//                 single: (single) {
//                   if (single.file != null) {
//                     widget.onMediaCaptured(single.file!);
//                   }
//                 },
//                 multiple: (multiple) {
//                   multiple.fileBySensor.forEach((key, value) {
//                     if (value != null) {
//                       widget.onMediaCaptured(value);
//                     }
//                   });
//                 },
//               );
//               break;
//             case (MediaCaptureStatus.capturing, false, true):
//               // 开始录像
//               setState(() {
//                 _isRecording = true;
//               });
//               break;
//             case (MediaCaptureStatus.success, false, true):
//               // 停止录像
//               setState(() {
//                 _isRecording = false;
//               });
//               break;
//             default:
//               break;
//           }
//         },
//         saveConfig: SaveConfig.photoAndVideo(
//           initialCaptureMode: CaptureMode.photo,
//           photoPathBuilder: (sensors) async {
//             final Directory extDir = await getTemporaryDirectory();
//             final testDir = await Directory(
//               '${extDir.path}/camera_media',
//             ).create(recursive: true);
//             if (sensors.length == 1) {
//               final String filePath =
//                   '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
//               return SingleCaptureRequest(filePath, sensors.first);
//             }
//             return MultipleCaptureRequest(
//               {
//                 for (final sensor in sensors)
//                   sensor:
//                       '${testDir.path}/${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg',
//               },
//             );
//           },
//           videoOptions: VideoOptions(
//             enableAudio: true,
//           ),
//           videoPathBuilder: (sensors) async {
//             final Directory extDir = await getTemporaryDirectory();
//             final testDir = await Directory(
//               '${extDir.path}/camera_media',
//             ).create(recursive: true);
//             if (sensors.length == 1) {
//               final String filePath =
//                   '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
//               return SingleCaptureRequest(filePath, sensors.first);
//             }
//             return MultipleCaptureRequest(
//               {
//                 for (final sensor in sensors)
//                   sensor:
//                       '${testDir.path}/${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.mp4',
//               },
//             );
//           },
//         ),
//         sensorConfig: SensorConfig.single(
//           sensor: Sensor.position(SensorPosition.back),
//         ),
//       ),
//       floatingActionButton: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (_isRecording)
//             FloatingActionButton(
//               onPressed: () {
//                 // 在录像过程中拍照
//                 _cameraController.takePicture();
//               },
//               child: const Icon(Icons.camera_alt),
//             ),
//           FloatingActionButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Icon(Icons.close),
//           ),
//         ],
//       ),
//     );
//   }
// }