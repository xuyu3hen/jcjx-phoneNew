import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../index.dart';
import '../../zjc_common/widgets/zjc_asset_picker.dart' as APC;

class SecEnter extends StatefulWidget {
  const SecEnter({Key? key}) : super(key: key);

  @override
  State createState() => _SecEnter();
}

class _SecEnter extends State<SecEnter> {
  // 创建 Logger 实例
  var logger = Logger(
    printer: PrettyPrinter(), // 漂亮的日志格式化
  );

  // 动力类型
  List<DynamicType> dynamicList = <DynamicType>[];
  String? dynamicCode;
  String? dynamicName;
  // 机型
  List<JcType> jcTypeList = <JcType>[];
  Map<dynamic, dynamic> jcTypeelected = {"name": "", "code": ""};
  // 车号
  List<RepairPlan> trainNumCodeList = <RepairPlan>[];
  Map<dynamic, dynamic> trainNumSelected = {"name": "", "code": ""};
  // 停留地点
  String? stoppingPlace;
  // 检修地点
  String? repairLocation;
  // 股道号
  String? trackNum;
  // 修程
  List<RepairProc> repairProList = <RepairProc>[];
  Map<dynamic, dynamic> repairProc = {"name": "", "code": ""};
  // 修次
  List<RepairTimes> repairTimesList = <RepairTimes>[];
  List<RepairTimes> repairTimesSelected = [];
  String repairTimes = "";
  // 入修时间
  // DateTime arrivePlatformTime = DateTime.now();
  String? arrivePlatformTime;
  // 接车时间
  // DateTime operateTime = DateTime.now();
  String? operateTime;
  // 油量
  // File? oilImage;
  List<AssetEntity> oilAssestPics = [];
  List<File> oilImage = [];
  // 防溜
  // File? slipImage;
  List<AssetEntity> slipAssestPics = [];
  List<File> slipImage = [];

  @override
  void initState() {
    super.initState();
    getDynamicType();
    getRepairProc();
  }

  @override
  void didUpdateWidget(SecEnter secEnter) {
    super.didUpdateWidget(secEnter);
    // getDynamicType();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("新增入段"),
      ),
      // resizeToAvoidBottomInset: false,
      body: _buildBody(),
      bottomNavigationBar: _footer(),
    );
  }

  Widget _buildBody() {
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(color: Colors.white),
        child: ListView(children: <Widget>[
          Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            ZjcFormSelectCell(
              title: "动力类型",
              text: dynamicName,
              hintText: "请选择",
              showRedStar: true,
              clickCallBack: () {
                ZjcCascadeTreePicker.show(
                  context,
                  data: json.decode(json.encode(dynamicList)),
                  labelKey: 'name',
                  valueKey: 'code',
                  isShowSearch: false,
                  // childrenKey: 'children',
                  title: "选择动力类型",
                  clickCallBack: (selectItem, selectArr) {
                    logger.i(selectArr);
                    setState(() {
                      dynamicName = selectItem["name"];
                      dynamicCode = selectItem["code"];
                      // 清表
                      jcTypeelected = {"name": "", "code": ""};
                      trainNumSelected = {"name": "", "code": ""};
                      getTypeCode();
                    });
                  },
                );
              },
            ),
            ZjcFormSelectCell(
              title: "机型",
              text: jcTypeelected["name"],
              hintText: "请选择",
              showRedStar: true,
              clickCallBack: () {
                if (dynamicName == "" || dynamicName == null) {
                  showToast('请先选择动力类型');
                } else {
                  ZjcCascadeTreePicker.show(
                    context,
                    data: json.decode(json.encode(jcTypeList)),
                    labelKey: 'name',
                    valueKey: 'code',
                    childrenKey: 'children',
                    title: "选择机型",
                    clickCallBack: (selectItem, selectArr) {
                      logger.i(selectArr);
                      setState(() {
                        jcTypeelected["name"] = selectItem["name"];
                        jcTypeelected["code"] = selectItem["code"];
                        // 清表
                        trainNumSelected = {"name": "", "code": ""};
                        getTrainNumCodeList();
                      });
                    },
                  );
                }
              },
            ),
            ZjcFormSelectCell(
              title: "车号",
              text: trainNumSelected["name"],
              hintText: "请选择",
              showRedStar: true,
              clickCallBack: () {
                if (jcTypeelected["name"] == "") {
                  showToast('请先选择机型');
                }
                if (trainNumCodeList.isEmpty) {
                  showToast("该机型下无车号");
                } else {
                  ZjcCascadeTreePicker.show(
                    context,
                    data: json.decode(json.encode(trainNumCodeList)),
                    labelKey: 'trainNum',
                    valueKey: 'code',
                    childrenKey: 'children',
                    title: "选择车号",
                    clickCallBack: (selectItem, selectArr) {
                      logger.i(selectArr);
                      setState(() {
                        trainNumSelected["name"] = selectItem["trainNum"];
                        trainNumSelected["code"] = selectItem["code"];
                      });
                    },
                  );
                }
              },
            ),
            ZjcFormInputCell(
              title: "停留地点",
              text: stoppingPlace,
              inputCallBack: (value) {
                stoppingPlace = value;
              },
            ),
            ZjcFormInputCell(
              title: "检修地点",
              text: stoppingPlace,
              inputCallBack: (value) {
                repairLocation = value;
              },
            ),
            ZjcFormInputCell(
              title: "股道号",
              text: stoppingPlace,
              inputCallBack: (value) {
                trackNum = value;
              },
            ),
            ZjcFormSelectCell(
              title: "修程",
              text: repairProc["name"],
              hintText: "请选择",
              clickCallBack: () {
                ZjcCascadeTreePicker.show(
                  context,
                  data: json.decode(json.encode(repairProList)),
                  labelKey: 'name',
                  valueKey: 'code',
                  isShowSearch: false,
                  title: "选择修程",
                  clickCallBack: (selectItem, selectArr) {
                    logger.i(selectArr);
                    setState(() {
                      repairProc["name"] = selectItem["name"];
                      repairProc["code"] = selectItem["code"];
                      getRepairTimes();
                    });
                  },
                );
              },
            ),
            ZjcFormSelectCell(
              title: "修次",
              // text: repairProc["name"],
              hintText: "",
              rightWidget: MultiSelectChipDisplay(
                items: repairTimesSelected
                    .map((e) => MultiSelectItem(e, e.name!))
                    .toList(),
                scroll: true,
                chipWidth: MediaQuery.of(context).size.width - 135.0,
              ),
              clickCallBack: () async {
                if (repairProc["name"] == "") {
                  showToast("请先选择修程");
                } else {
                  final items = repairTimesList
                      .map((vehicle) =>
                          MultiSelectItem<RepairTimes>(vehicle, vehicle.name!))
                      .toList();
                  await showDialog(
                      context: context,
                      builder: (ctx) {
                        return MultiSelectDialog(
                          items: items,
                          initialValue: repairTimesSelected,
                          onSelectionChanged: (p0) {},
                          onConfirm: (p0) {
                            setState(() {
                              repairTimesSelected = p0;
                            });
                          },
                        );
                      });
                }
              },
            ),
            // ZjcFormSelectCell(
            //   title: "入修时间",
            //   text: arrivePlatformTime,
            //   hintText: "请选择",
            //   showRedStar: true,
            //   clickCallBack: () async {
            //     var time = await selectDate("datetime");
            //     setState(()  {
            //       arrivePlatformTime = time;
            //     });
            //   },
            // ),
            // ZjcFormSelectCell(
            //   title: "接车时间",
            //   text: operateTime,
            //   hintText: "请选择",
            //   showRedStar: true,
            //   clickCallBack: () async {
            //     var time = await selectDate("datetime");
            //     setState(()  {
            //       operateTime = time;
            //     });
            //   },
            // ),
            const Text("上传油量油位"),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  border: Border.all(color: Colors.brown)),
              child: ZjcAssetPicker(
                assetType: APC.AssetType.image,
                maxAssets: 1,
                selectedAssets: oilAssestPics,
                // bgColor: Colors.grey,
                callBack: (assetEntityList) async {
                  logger.i('assetEntityList-------------');
                  logger.i(assetEntityList);
                  if (assetEntityList.isNotEmpty) {
                    var asset = assetEntityList[0];
                    var pic = await asset.file;
                    logger.i(await asset.file);
                    logger.i(await asset.originFile);
                    oilImage.insert(0, pic!);
                  } else {
                    oilImage = [];
                  }
                  logger.i('assetEntityList-------------');
                },
              ),
            ),
            // if(slipImage == null)
            //   PhotoArea(slipImage),
            // if(slipImage != null)
            //   Container(child: Image.file(slipImage!,width: 200,height: 200,),),
            const Text("上传防溜"),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  border: Border.all(color: Colors.brown)),
              child: ZjcAssetPicker(
                assetType: APC.AssetType.image,
                maxAssets: 1,
                selectedAssets: slipAssestPics,
                // bgColor: Colors.grey,
                callBack: (assetEntityList) async {
                  logger.i('assetEntityList-------------');
                  logger.i(assetEntityList);
                  if (assetEntityList.isNotEmpty) {
                    var asset = assetEntityList[0];
                    var pic = await asset.file;
                    logger.i(await asset.file);
                    logger.i(await asset.originFile);
                    slipImage.insert(0, pic!);
                  } else {
                    slipImage = [];
                  }
                },
              ),
            ),
            // if(oilImage == null)
            //   PhotoArea(oilImage),
            // if(oilImage != null)
            //   Container(
            //     child: Image.file(oilImage!,width: 200,height: 200,),
            //   ),
            // ElevatedButton(onPressed: newEntry, child: const Text("接     车",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
          ])
        ]));
    // SingleChildScrollView(
    //   controller: scrollController,
    //   child:
    //   ListView(
    //     padding: EdgeInsets.all(20),
    //     children: <Widget>[
    //       MultiSelectDropDown(
    //         hint: "修程",
    //         hintStyle:TextStyle(fontSize: 16,color: Colors.deepPurple),
    //         onOptionSelected: (List<ValueItem> selectedOptions) {
    //           if(selectedOptions.isNotEmpty){
    //             repairProcCode = selectedOptions[0].value;
    //             print("已选中$repairProcCode");
    //             getRepairTimes();
    //           }
    //         },
    //         options: _dyTypeList(repairProList),
    //         selectionType: SelectionType.single,
    //         chipConfig: const ChipConfig(wrapType: WrapType.wrap),
    //         dropdownHeight: 300,
    //         optionTextStyle: const TextStyle(fontSize: 16),
    //         selectedOptionIcon: const Icon(Icons.check_circle),
    //       ),
    //       const SizedBox(height: 10,),
    //       MultiSelectDropDown(
    //         hint: "修次",
    //         hintStyle:TextStyle(fontSize: 16,color: Colors.deepPurple),
    //         onOptionSelected: (List<ValueItem> selectedOptions) {
    //           if(selectedOptions.isNotEmpty){
    //             repairTimesSelected = selectedOptions;
    //             print(selectedOptions);
    //           }
    //         },
    //         options: _dyTypeList(repairTimesList),
    //         selectionType: SelectionType.multi,
    //         chipConfig: const ChipConfig(wrapType: WrapType.wrap),
    //         dropdownHeight: 300,
    //         optionTextStyle: const TextStyle(fontSize: 16),
    //         selectedOptionIcon: const Icon(Icons.check_circle),
    //       ),
    //       // DatetimeFormitem(
    //       //   type: DateTimePickerType.datetime,
    //       //   datetime: arrivePlatformTime,
    //       //   title: "入修时间",
    //       // ),
    //       // DatetimeFormitem(
    //       //   type: DateTimePickerType.datetime,
    //       //   datetime: operateTime,
    //       //   title: "接车时间"
    //       // ),
    //       Text("上传防溜"),
    //       if(slipImage == null)
    //         PhotoArea(slipImage),
    //       if(slipImage != null)
    //         Container(child: Image.file(slipImage!,width: 200,height: 200,),),
    //       Text("上传油量油位"),
    //       if(oilImage == null)
    //         PhotoArea(oilImage),
    //       if(oilImage != null)
    //         Container(
    //           child: Image.file(oilImage!,width: 200,height: 200,),
    //         ),
    //       ElevatedButton(onPressed: newEntry, child: const Text("接     车",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
    //     ]
    //   // ),
    // );
  }

  // 函数区
  // 动力类型
  void getDynamicType() async {
    var r = await ProductApi().getDynamicType();
    if (r.rows != []) {
      setState(() {
        dynamicList = r.rows!;
      });
    }
  }

  // 机型
  void getTypeCode() async {
    var r = await ProductApi().getJcType(queryParametrs: {
      'dynamicCode': dynamicCode,
    });
    if (r.rows != []) {
      setState(() {
        jcTypeList = r.rows!;
      });
    }
  }

  // 车号
  void getTrainNumCodeList() async {
    var r = await ProductApi().getRepairPlanList(queryParametrs: {
      "pageNum": 0,
      "pageSize": 0,
      "trainType": jcTypeelected["name"]
    });
    if (r.rows != []) {
      setState(() {
        trainNumCodeList = r.rows!;
      });
    }
  }

  // 修程
  void getRepairProc() async {
    var r = await ProductApi().getRepairProc();
    if (r.rows != []) {
      setState(() {
        repairProList = r.rows!;
      });
    }
  }

  // 修次
  void getRepairTimes() async {
    var r = await ProductApi().getRepairTimes();
    if (r.rows != []) {
      setState(() {
        repairTimesList = r.rows!;
      });
    }
  }

  // 新增入修
  Future<String> newEntry() async {
    for (var item in repairTimesSelected) {
      if (repairTimes != "") {
        repairTimes = "${item.name},$repairTimes";
      } else {
        repairTimes = item.name!;
      }
    }
    Map<String, dynamic> queryParameters = {
      'dynamicCode': dynamicCode,
      'typeCode': jcTypeelected["code"],
      'trainNum': trainNumSelected["name"],
      'stoppingPlace': stoppingPlace,
      'repairLocation': repairLocation,
      'trackNum': trackNum,
      'repairProcCode': repairProc["code"],
      'repairTimes': repairTimes,
    };
    var r = await ProductApi().newTrainEntry(queryParametrs: queryParameters);
    if (r["code"] == "S_T_S001") {
      showToast("新增入修成功");
      return r["data"];
    } else {
      showToast("新增入修失败");
      return "";
    }
  }

  // 上传防溜函数
  Future<int> uploadSlip(val) async {
    var r = await ProductApi().upSlipImg(
        queryParametrs: {"trainEntryCode": val},
        imagedata: File(slipImage[0].path));
    if (r == 200) {
      showToast("上传防溜成功");
      // uploadOil(val);
    }
    return r;
  }

  // 上传油量函数
  Future<int> uploadOil(val) async {
    var r = await ProductApi().uploadOilImg(
        queryParametrs: {"trainEntryCode": val},
        imagedata: File(oilImage[0].path));
    if (r == 200) {
      showToast("上传油量成功");
    }
    return r;
  }

  Widget _footer() {
    return SafeArea(
        child: InkWell(
      onTap: () async {
        // var submit;
        newEntry().then((code) => {
              if (code != "")
                {
                  if (oilImage.isNotEmpty)
                    {
                      uploadOil(code).then((e) => {
                            if (slipImage.isNotEmpty)
                              {
                                uploadSlip(code).then((value) => {
                                      if (value == 200)
                                        {
                                          exitDialog(),
                                        }
                                    })
                              }
                            else
                              {
                                exitDialog(),
                              }
                          }),
                    }
                  else if (slipImage.isNotEmpty)
                    {
                      uploadSlip(code).then((value) => {
                            if (value == 200)
                              {
                                exitDialog(),
                              }
                          })
                    }
                  else
                    {
                      exitDialog(),
                    }
                }
            });
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.lightBlue[200],
        height: 50,
        child: const Text('新 增 入 段',
            style: TextStyle(color: Colors.black, fontSize: 18)),
      ),
    ));
  }

  void exitDialog() {
    SmartDialog.show(
        clickMaskDismiss: false,
        builder: (con) {
          return Container(
            height: 150,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "新增入段提报成功",
                  style: TextStyle(fontSize: 18),
                ),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints.expand(height: 30, width: 160),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      SmartDialog.dismiss()
                          .then((value) => Navigator.of(context).pop());
                    },
                    label: const Text('确定'),
                    icon: const Icon(Icons.system_security_update_good_sharp),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Future<String> selectDate(str) async {
    DateTimePickerType dt;
    if (str == "datetime") {
      dt = DateTimePickerType.datetime;
    } else if (str == "date") {
      dt = DateTimePickerType.date;
    } else {
      dt = DateTimePickerType.time;
    }

    var val = await showBoardDateTimePicker(
      context: context,
      pickerType: dt,
    );
    if (val != null && str == "datetime") {
      String str =
          formatDate(val, [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]);

      return str;
    } else if (val != null && str == "date") {
      String str = formatDate(val, [yyyy, '-', mm, '-', dd]);
      return str;
    } else {
      return "";
    }
  }
}
