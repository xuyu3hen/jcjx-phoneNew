import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jcjx_phone/index.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/prework/MainStructure.dart';
import '../../models/prework/packageUser.dart';
import '../../models/prework/workInstructPackageUser .dart';
import 'package:http/http.dart' as http;

class preDispatchWork extends StatefulWidget {
  const preDispatchWork({super.key});

  
  State<preDispatchWork> createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<preDispatchWork> {

    late WebViewController _webViewController;




  @override  
  void initState(){

    super.initState();
          // 创建带有Authorization头的请求
    final request = http.Request('GET', Uri.parse('http://10.102.72.180/maintenanceTask/preDispatch'))
     ..headers['Authorization'] = Global.profile.data!.access_token!;

    // 初始化WebView控制器，并加载带有授权信息的请求
    _webViewController = WebViewController()
     ..setJavaScriptMode(JavaScriptMode.unrestricted)
     ..loadRequest(request.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预派工'),
      ),
      body: WebViewWidget(
        controller: _webViewController,
      ),
    );
  }

 
}
