import 'dart:convert';
import 'package:jcjx_phone/config/index.dart';
import '../../../index.dart';
import 'package:flutter_custom_dropdown/flutter_custom_dropdown.dart' as downmenu;
import '../../../zjc_common/widgets/zjc_empty_view.dart';

class TaskPackageBackup extends StatefulWidget{
  const TaskPackageBackup({super.key});

  @override
  State<TaskPackageBackup> createState() => _TaskPackageBackupState();
}

class _TaskPackageBackupState extends State<TaskPackageBackup> {

  // 列表尽头
  // static const loadingTag = '##loading##';
  var _items = <IndividualTaskPackage>[];

  // 筛选器相关
  downmenu.DropdownMenuController? controller;
  late GlobalKey _globalKey;

  // 动力类型
  List<Map<String,dynamic>> dynamicList = [];
  String? dynamicCode;
  // 机型
  List<Map<String,dynamic>> jcTypeList = [];
  String? typeName;
  // 车号code
  String? trainCode;

  // 动力类型
  void getDynamicType() async {
    SmartDialog.showLoading();
    var r = await ProductApi().getDynamicType();
    if(r.rows != []){
      setState(() {
        dynamicList = r.rows!.map((e){
          var p = e.toJson();
          p['title'] = p['name'];
          return p;
        }).toList();
        dynamicCode = dynamicList[0]['code'];
      });
    }
    SmartDialog.dismiss(status: SmartStatus.loading);
  }

  // 机型
  void getTypeCode() async {
    var r = await ProductApi().getJcType(
      queryParametrs:{
        'dynamicCode':dynamicCode,
      }
    );
    if(r.rows != []){
      setState(() {
        jcTypeList = r.rows!.map((e){
          var p = e.toJson();
          p['title'] = p['name'];
          return p;
        }).toList();
        typeName = jcTypeList[0]['name'];
      });
    }
  }

  // 个人作业包
  void getIndividualTaskPackage() async {
    SmartDialog.showLoading();
    _items = <IndividualTaskPackage>[];
    var r = await JtApi().getIndividualTaskPackage(
      queryParameters:{
        'trainEntryCode': trainCode,
      }
    );
    if(r.message == "操作成功"&&r.data != []){
      setState(() {
        // 作业包表数据获取
        _items.insertAll(_items.length, r.data!);
      });
    }
    SmartDialog.dismiss(status: SmartStatus.loading);
  }

  // AB端切换
  Future<int> updateWorkInstructPackage(val) async {
    print(json.decode(json.encode(val)));
    var list = <Map<String,dynamic>>[];
    list.insert(0, json.decode(json.encode(val)));
    var r = await JtApi().updateWorkInstructPackage(
      queryParameters:list
    );
    if(r['message'] == "操作成功"&&r['code']== 200){
      print('切换AB端成功');
    }else{
      showToast('切换AB端出现错误');
    }
    return r['code'];
  }

  @override
  void initState() {
    super.initState();
    getDynamicType();
    _globalKey = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("个人作业包"),
      ),
      body: _filter(),
    );
  }
  // 过滤器
  Widget _filter() {
    return downmenu.DefaultDropdownMenuController(
      onSelected: ({int? menuIndex, dynamic data}) {
        print("int menuIndex, dynamic data = $menuIndex,$data");
        if (menuIndex == 0) {
          // value1 = '选中下标$menuIndex,\n选中内容$data';
          setState(() {
            print("看看数据${data[0]['code']}");
            dynamicCode = data[0]['code'];
            getTypeCode();
          });
        }
        if (menuIndex == 1) {
          setState(() {
            print("看看数据$data");
            typeName = data[0]['name'];
          });
        }
        if (menuIndex == 2) {
          setState(() {
            print("看看数据$data");
            trainCode = data['urgency'];
            getIndividualTaskPackage();
          });
        }
        // setState(() {});
      },
      child: Stack(
        key: _globalKey,
        children: [
          Column(
            children: [
              Container(
                  color: Colors.white,
                  child: buildDropdownHeader()),
              Expanded( child: _buildBody()),
            ],
          ),
          Padding(padding: const EdgeInsets.only(top: 40), child: buildDropdownMenu(context))
        ],
      ),
    );
  }

  downmenu.DropdownHeader buildDropdownHeader({downmenu.DropdownMenuHeadTapCallback? onTap}) {
    return downmenu.DropdownHeader(
      isSideline: false,
      onTap: onTap,
      titles: ['动力类型', '机型','车号'],
      selectIsChangingColor: true,
      // specialModules: [1, 2],
      ///特殊模块,选中数据只亮起,不需要更改头部title,下标为1
      // 要想正常回显需要Map中含有title键值对
    );
  }

  downmenu.DropdownMenu buildDropdownMenu(BuildContext context) {
    return downmenu.DropdownMenu(menus: [
      downmenu.DropdownMenuBuilder(
          builder: (BuildContext context) {
            return downmenu.DropdownListMenu(
              selectedIndex: dynamicList[0],
              isOperatingButton: false,
              keyWords: "code",
              data: dynamicList,
              valueKey: 'name',
              itemBuilder: downmenu.buildCheckItem,
            );
          },
          screenHeight: MediaQuery.of(context).size.height,
          draughtHeight: 50 * 5,
          bottomSpacingHeight: 168.0),
      downmenu.DropdownMenuBuilder(
          builder: (BuildContext context) {
            // print(jcTypeList);
            if(jcTypeList.isEmpty){
              return const SizedBox();
            }else{
              return downmenu.DropdownListMenu(
                selectedIndex: jcTypeList[0],
                isOperatingButton: false,
                keyWords: "code",
                data: jcTypeList,
                valueKey: 'name',
                itemBuilder: downmenu.buildCheckItem,
              );
            }
          },
          screenHeight: MediaQuery.of(context).size.height,
          draughtHeight: 50 * 5,
          bottomSpacingHeight: 168.0),
      downmenu.DropdownMenuBuilder(
          builder: (BuildContext context) {
            return downmenu.DropdownMenuCustomize(
              data: [],
              itemBuilder: financialMoreTemplate,
            );
          },
          screenHeight: MediaQuery.of(context).size.height,
          draughtHeight: 60 * 6.66,
          bottomSpacingHeight: 168.0 + 50.0),
    ]);
  }

  Widget financialMoreTemplate(BuildContext context, List<dynamic> data, downmenu.DropdownMenuController? controller) {
    return _FinancialMoreTemplate(controller,typeName:typeName);
  }

  // 列表
  Widget _buildBody(){
    if(_items.isEmpty&&trainCode == ""){
      return const ZjcEmptyView(text:"请先选择车号");
    }else if(_items.isEmpty){
      return const ZjcEmptyView(text:"暂无数据");
    }
    else{
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.topCenter,
              height: (MediaQuery.of(context).size.height)*0.8,
              child: ListView.separated(
                itemCount: _items.length,
                itemBuilder: (context,index){
                  return _itemWidget(_items[index]);
                }, 
                separatorBuilder: (context,index) => const SizedBox(height: .0,), 
              )
            )
          ]
        ),
      );
    }
  }

  // 数据模板
  Widget _itemWidget(IndividualTaskPackage item) {
    var cell = Padding(
      padding: const EdgeInsetsDirectional.all(5),
      child: Container(
        margin: const EdgeInsets.all(3),
        constraints: const BoxConstraints.tightFor(height: 80),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(2.0, 2.0),
              blurRadius: 4.0
            )
          ],
        ),
        child: InkWell(
          onTap: () {
            if(item.wholePackage!&&item.ends == null){
              showToast('请先选择作业包AB端');
            }else{
              Navigator.of(context).pushNamed('certainPackage',arguments: item);
              // .then((value) => {
              // });
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if(item.wholePackage!)...[
                ListTile(
                  dense: true,
                  leading: Text("${item.name}",style: TextStyle(fontSize: 18.0),),
                  title: Text("${item.station}",style: TextStyle(fontSize: 16.0)),
                  // subtitle: Text(""),
                  trailing:ElevatedButton(onPressed: (){
                    changeABDialog(item);
                  }, 
                  child: Text(item.ends??'A/B',style: tileText(18.0,bold: FontWeight.bold,col: item.ends =='B'?Colors.orange:Colors.red),)),
                ),
              ]else...[
                ListTile(
                  dense: true,
                  leading: Text("${item.name}",style: TextStyle(fontSize: 18.0),),
                  title: Text("${item.station}",style: TextStyle(fontSize: 16.0)),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('作业进度'),
                  SizedBox(
                    height: 5,
                    width: 270,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(Colors.blue),
                      value: item.progress == 0? 0 : item.progress!/100,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
    return cell;
  }

  // 字体
  TextStyle tileText(val,{bold,col}){
    return TextStyle(
      fontSize: val,
      fontWeight: bold != null?FontWeight.bold : FontWeight.normal,
      color: col
    );
  }

  Future<void> changeABDialog(item) async {
    SmartDialog.show(clickMaskDismiss: false,
      builder: (con){
        return StatefulBuilder(builder: (context, setDialogState) {
          return Container(
            height: 120,
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: 80,
                      child: RadioListTile<String>(
                        title: const Text('A'),
                        value: 'A', 
                        groupValue: item.ends, 
                        onChanged: (String? value){
                          setDialogState(() {
                            item.ends = value;
                          });
                        }
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: RadioListTile<String>(
                        title: const Text('B'),
                        value: 'B', 
                        groupValue: item.ends, 
                        onChanged: (String? value){
                          setDialogState(() {
                            item.ends = value;
                          });
                        }
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: (){
                        SmartDialog.dismiss();
                      },
                      label: Text('取消'),
                      icon:Icon(Icons.close),
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.grey[200]))
                    ),
                    ElevatedButton.icon(
                      onPressed: (){
                        updateWorkInstructPackage(item).then((value){
                          SmartDialog.dismiss().then((e)=>getIndividualTaskPackage());
                        });
                      },
                      label: Text('确定'),
                      icon:Icon(Icons.system_security_update_good_sharp),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      );
    });
  }
  
}

class _FinancialMoreTemplate extends StatefulWidget {
  final downmenu.DropdownMenuController? controller;
  final String? typeName;

  const _FinancialMoreTemplate(this.controller,{this.typeName});

  @override
  __FinancialMoreTemplateState createState() => __FinancialMoreTemplateState();
}

class __FinancialMoreTemplateState extends State<_FinancialMoreTemplate> {
  Map<String, Object?> _map = {
    'urgency': null,
    'title':null,
  };

  // 车号
  List<Map<String,dynamic>> trainNumCodeList = [];
  String? trainNum;
  String? trainCode;

  
  @override
  void initState(){
    super.initState();
    getTrainNumCodeList();
  }

  @override
  void didUpdateWidget(_FinancialMoreTemplate financialMoreTemplate){
    super.didUpdateWidget(financialMoreTemplate);
    getTrainNumCodeList();
  }

  // 车号
  void getTrainNumCodeList() async {
    var r = await ProductApi().getRepairPlanList(
      queryParametrs: {
        "pageNum":0,
        "pageSize":0,
        "typeName":widget.typeName
      }
    );
    // print(r.rows);
    setState(() {
      trainNum = "";
      trainNumCodeList = r.rows!.map((e) => e.toJson()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if(trainNumCodeList.isEmpty){
      return  Container(
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24.0,
            height: 24.0,
            child: CircularProgressIndicator(strokeWidth: 2.0,)
          ),
        );
    }else{
      return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                padding: const EdgeInsets.all(0.0),
                children: [
                  const SizedBox(
                    height: 12.0,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '请选择车号',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0XFF303133)),
                          ),
                        ),
                        const SizedBox(
                          height: 12.0,
                        ),
                        GridView.count(
                          childAspectRatio: 109 / 40,
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(0),
                          primary: false,
                          shrinkWrap: true,

                          ///添加当前可解决Vertical viewport was given unbounded height.报错
                          crossAxisCount: 3,
                          children: _urgencyList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 34.0,
                  ),
                ],
              )),
              downmenu.FilterButton(
                fixOnTap: () {
                  assert(widget.controller != null);
                  print("ss$_map");
                  widget.controller!.select(_map);
                },
                resetOnTap: () {
                  widget.controller!.select({});
                },
              )
            ],
          ),
        ),
      );
    }
  }

  List<Widget> _urgencyList() {
    return trainNumCodeList.map((item) {
      bool _isSelected = false;
      if (_map['urgency'] != null) {
        _isSelected = _map['urgency'] == item['code'];
      } else {
        _isSelected = item['trainNum'] == '-1';
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Map<String, Object?> _item = {}..addEntries(_map.entries);
          if (item['serialNum'] == -1) {
            _item['urgency'] = null;
            _item['title'] = null;
          } else {
            _item['urgency'] = item['code'];
            _item['title'] = item['trainNum'];
          }
          setState(() {
            _map = {}..addEntries(_item.entries);
          });
        },
        child: LabelWidget(
          isBorder: !_isSelected,
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          padding: const EdgeInsets.all(0.0),
          alignment: Alignment.center,
          border: _isSelected ? null : Border.all(width: .5, color: Color(0XFFD9D9D9)),
          fontColor: _isSelected ? Color(0XFF00CCA9) : Color(0XFF909399),
          labelBgColor: _isSelected ? Color(0X2100CCA9) : Colors.white,
          fontSize: 16,
          tagItem: {'name': item['trainNum']},
        ),
      );
    }).toList();
  }
}