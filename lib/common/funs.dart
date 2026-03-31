import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

Widget gmAvatar(String url, {
  double width = 30,
  double? height,
  BoxFit? fit,
  BorderRadius? borderRadius,
}) {
  var placeholder = Image.asset(
      "imgs/avatar-default.png", //头像占位图
      width: width,
      height: height
  );
  return ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.circular(2),
    child: CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>placeholder,
      errorWidget: (context, url, error) =>placeholder,
    ),
  );
}

void showToast(String text, {dynamic gravity, dynamic toastLength}) {
  // FlutterSmartDialog.showToast(text);
}

void showLoading(context, [String? text]) {
  String text1 = text ?? "Loading...";
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return Center(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3.0),
                boxShadow: const [
                  //阴影
                  BoxShadow(
                    color: Colors.black12,
                    //offset: Offset(2.0,2.0),
                    blurRadius: 10.0,
                  )
                ]),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 120, minWidth: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    text1,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      });
}

String formatEndsSuffix(dynamic ends) {
  final raw = (ends ?? '').toString().trim();
  if (raw.isEmpty) {
    return '';
  }
  var v = raw.toUpperCase();
  if (v.endsWith('端')) {
    v = v.substring(0, v.length - 1).trim();
  }
  if (v == 'A' || v == 'B') {
    return v;
  }
  if (v == 'AB' || v == 'A/B' || v == r'A\B') {
    return 'A/B';
  }
  return raw;
}

String formatTrainNumWithEnds(dynamic trainNum, dynamic ends) {
  final tn = (trainNum ?? '').toString().trim();
  if (tn.isEmpty) {
    return '';
  }
  final suffix = formatEndsSuffix(ends);
  return suffix.isEmpty ? tn : '$tn$suffix';
}

dynamic extractEnds(dynamic obj) {
  if (obj is Map) {
    for (final entry in obj.entries) {
      if (entry.key.toString().toLowerCase() == 'ends') {
        return entry.value;
      }
    }
    final nested = obj['c4c5ledger'];
    if (nested is Map) {
      for (final entry in nested.entries) {
        if (entry.key.toString().toLowerCase() == 'ends') {
          return entry.value;
        }
      }
    }
  }
  return null;
}
