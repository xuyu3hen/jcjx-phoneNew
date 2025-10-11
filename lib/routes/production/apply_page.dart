import 'dart:math';

import 'package:jcjx_phone/routes/production/mutual_startwork.dart';
import 'package:jcjx_phone/routes/production/package_mutual_deal.dart';

import '../../index.dart';
import 'jt_startwork.dart';

//范围作业互检
class ApplyList extends StatefulWidget {
  final String trainNum;
  final String trainNumCode;
  final String typeName;
  final String typeCode;
  final String trainEntryCode;
  const ApplyList(
      {Key? key,
      required this.trainNum,
      required this.trainNumCode,
      required this.typeName,
      required this.typeCode,
      required this.trainEntryCode})
      : super(key: key);
  @override
  State<ApplyList> createState() => _JtShowPageState();
}

class _JtShowPageState extends State<ApplyList> {
  

  @override
  void initState() {
  
    super.initState();

  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("调车申请单"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  // 添加状态筛选相关变量
  late List<Map<String, dynamic>> statusFilterList = [
    {"name": "待互检", "value": 1},
    {"name": "已开工", "value": 6},
  ];
  late Map<String, dynamic> statusFilterSelected = {"name": "待互检", "value": 1};

  Widget _buildBody() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: ListView(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // ZjcFormSelectCell(
              //   title: "动力类型",
              //   text: dynamciTypeSelected["name"],
              //   hintText: "请选择",
              //   showRedStar: true,
              //   clickCallBack: () {
              //     if (dynamicTypeList.isEmpty) {
              //       showToast("无动力类型选择");
              //     } else {
              //       ZjcCascadeTreePicker.show(
              //         context,
              //         data: dynamicTypeList,
              //         labelKey: 'name',
              //         valueKey: 'code',
              //         childrenKey: 'children',
              //         title: "选择动力类型",
              //         clickCallBack: (selectItem, selectArr) {
              //           logger.i(selectArr);
              //           setState(() {
              //             dynamciTypeSelected["code"] = selectItem["code"];
              //             dynamciTypeSelected["name"] = selectItem["name"];
              //             getJcType();
              //           });
              //         },
              //       );
              //     }
              //   },
              // ),
              Row(
                children: [
                  Expanded(
                    child: ZjcFormSelectCell(
                      title: "机型",
                      text: widget.typeName,
                      hintText: "请选择",
                      showRedStar: true,
                      clickCallBack: null,
                    ),
                  ),
                  Expanded(
                    child: ZjcFormSelectCell(
                      title: "车号",
                      text: widget.trainNum,
                      hintText: "请选择",
                      showRedStar: true,
                      clickCallBack: null,
                    ),
                  ),
                ],
// ... existing code ...
              ),
              
            ],
          ),
        ],
      ),
    );
  }
}
