

import 'package:jcjx_phone/index.dart';

class RollCall extends StatefulWidget{
  const RollCall({super.key});

  @override
  State<RollCall> createState() => _RollCallState();
  
}

class _RollCallState extends State<RollCall>{

  var logger = AppLogger.logger;

  // 机型
  List? jcTypeList;
  String? dynamicCode;
  String? typeName;
  String? typeCode;
  // 修程
  List? repairProcList;
  String? repairProcName;
  String? repairProcCode;
  // 工序节点
  List? repairMainNodeList;
  String? repairMainNodeName;
  String? repairMainNodeCode;
  // 作业包分配
  List<PackageUser>? packageUserList;
  // 班组人员数据
  List<dynamic> userList = [];
  PackageUserDTOList? packageSelected;
  List<String> repairPersonnelSelected = [];
  List<String> assistantSelected = [];

  // 动力类型-机型
  void getDynamicAndJcType() async {
    var r = await ProductApi().getDynamicAndJcType(
    );
    if(r != []&&r != null){
      setState(() {
        jcTypeList = r;
      });
    }else{
      showToast('机型列表获取出错');
    }
  }

  // 获取修制-修程
  void getSysAndProc() async {
    var r = await ProductApi().getSysAndProc(
      queryParameters:{
        'dynamicCode':dynamicCode
      }
    );
    if(r != []&&r != null){
      setState(() {
        repairProcList = r;
      });
    }else{
      showToast('获取修制-修程列表出错');
    }
  }

  // 获取工序节点
  void getRepairMainNode() async {
    var r = await ProductApi().getRepairMainNode(
      queryParameters:{
        'deptIds':Global.profile.permissions!.user.dept!.parentId,
        'repairProcCode':repairProcCode,
        'pageNum':0,
        'pageSize':0
      }
    );
    if(r != []){
      setState(() {
        repairMainNodeList = r;
      });
    }else{
      showToast('获取工序节点出错');
    }
  }

  // 获取作业包
  void getPackageUserList() async {
    var r = await JtApi().getPackageUserList(
      queryParameters:{
        'deptId':Global.profile.permissions!.user.deptId,
        'typeCode':typeCode,
        'repairMainNodeCode':repairMainNodeCode,
      }
    );
    if(r.code == 'S_F_S000'){
      setState(() {
        packageUserList = r.data;
      });
    }else{
      showToast('获取作业包出错');
    }
  }
  
  // 查询班组人员
  void getJtUsers() async {
    try{
      var r = await JtApi().getUserList(
        queryParametrs: {
          'pageNum' : 0,
          'pageSize' : 0,
          'deptId' : Global.profile.permissions?.user.dept?.deptId,
        }
      );
      if(r != []&&r != null){
        setState(() {
          userList = r['rows'];
          for (var element in userList) {
            element['repairF'] = false;
            element['assistantF'] = false;
          }
        });
        // log('${userList[0]}');
      }else{
        showToast("未能获取班组人员");
      }
    }catch(e){
      logger.e("$e");
    }
  }

  @override
  void initState() {
    super.initState();
    getDynamicAndJcType();
    getJtUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("开工点名"),
      ),
      // 打开侧边栏需要传递更低一级context
      body: Builder(builder:(BuildContext context) {
        return _body(context);
      }),
      endDrawer: _personDrawer(),
    );
  }

  Widget _body(BuildContext context){
    if(jcTypeList == null){
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: 
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              width: 40.0,
              height: 40.0,
              child: CircularProgressIndicator(
                strokeWidth: 4.0,
              )),
            const SizedBox(
              height: 20.0,
            ),
            Text("正在获取动力类型-机型数据",
              style: TextStyle(color: Colors.blue[700]),
            ),
          ],
        )
      );
    }else{
      return _main(context);
    }
  }

  Widget _filter(){
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: Divider.createBorderSide(context),
        ),
      ),
      child: SizedBox(
        height: 40.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildItem(typeName,"机型",jctypeListSelect),
            buildItem(repairProcName,"修程",repairProcListSelect),
            buildItem(repairMainNodeName,"工序节点",repairMainNodeListSelect),
          ],
        )),
    );
  }

  Widget _personDrawer(){
    return Drawer(
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(),
            Expanded(child: _buildMenus()),
            _drawerFooter(),
          ],
        )
      ),
    );
  }

  Widget _buildMenus() {
    return Consumer<UserModel>(
      builder: (BuildContext context,UserModel userModel,Widget? child){
        return ListView.separated(
          // padding: EdgeInsets.only(left: 20,right: 20),
          itemCount: userList.length,
          itemBuilder: (context,index){
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:<Widget>[
                SizedBox(
                  width: 60.0,
                  child: Text("${userList[index]['nickName']}",style: tileText(18.0),),
                ),
                Checkbox(
                value: userList[index]['repairF'],
                activeColor: const Color.fromARGB(255, 59, 58, 58),
                onChanged: (dynamic value) {
                  setState(() {
                    userList[index]['repairF'] = value;
                  });
                }),
                Checkbox(
                value: userList[index]['assistantF'],
                activeColor: const Color.fromARGB(255, 59, 58, 58),
                onChanged: (dynamic value) {
                  setState(() {
                    userList[index]['assistantF'] = value;
                  });
                }),
              ] 
              
            );
          },
          separatorBuilder: (context,index) => const SizedBox(height: .0,), 
        );
      }
    );
  }

  Widget _buildHeader() {
    return Consumer<UserModel>(
      builder: (BuildContext context,UserModel value,Widget? child){
        return GestureDetector(
          child: Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.only(top:10,bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text('姓名',style: tileText(20.0,bold: true),),
                Text('施修',style: tileText(20.0,bold: true),),
                Text('协助',style: tileText(20.0,bold: true),)
              ]),
          ),
        );
      }
    );
  }

  Widget _drawerFooter(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        ElevatedButton(onPressed: (){
          setState((){
            for (var element in userList) {
              element['repairF'] = false;
              element['assistantF'] = false;
            }
          });
        },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 40),
            backgroundColor: const Color.fromRGBO(182, 182, 182, 1)
          ), child: const Text('重置'),),
        ElevatedButton(onPressed: () async {
          // if(repairPersonnelSelected.isEmpty){
          //   showToast('请选择主修');
          // }else if(assistantSelected.isEmpty){
          //   showToast('请选择辅助修');
          // }else{
            try{
              SmartDialog.showLoading();
              // holy shit
              List reList = userList.where((element) => element['repairF'] == true).toList();
              List asList = userList.where((element) => element['assistantF'] == true).toList();
              String repairStr = "";String repairNameStr = "";
              String asStr = "";String asNameStr = "";
              // 数组指定属性拼接
              repairStr = reList.map((e){return (e['userId']).toString();}).join(',');
              repairNameStr = reList.map((e){return (e['nickName']).toString();}).join(',');
              asStr = asList.map((e){return (e['userId']).toString();}).join(',');
              asNameStr = asList.map((e){return (e['nickName']).toString();}).join(',');

              for(var e in packageSelected!.workInstructPackageUserList!){
                e.repairPersonnel = repairStr;
                e.repairPersonnelName = repairNameStr;
                e.assistant = asStr;
                e.assistantName = asNameStr;
              }

              // list转mapList,不转接口报500
              var list = <Map<String,dynamic>>[];
              list = packageSelected!.workInstructPackageUserList!.map((e){
                return e.toJson();
                }).toList();
              
              var submit = await JtApi().updateInstructPackageUser(
                queryParameters: list
              );
              if(submit['code'] != "S_T_S003"){
                showToast("${submit['message']}");
              }
            }on DioException catch(e){
              showToast('$e');
            }finally{
              SmartDialog.dismiss(status: SmartStatus.loading);
              Navigator.pop(context);
              searchPackage();
            }
          // }
        },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 40),
          ), child: const Text('确认'),  
        )
      ],
    );
  }

  // 动力类型-机型选择
  void jctypeListSelect(){
    ZjcCascadeTreePicker.show(context,
      data: jcTypeList!,
      labelKey: 'name',
      valueKey: 'code',
      childrenKey: 'jcTypeList',
      isShowSearch: false,
      title: "选择机型",
      clickCallBack: (selectItem, selectArr) {
        // print(selectArr);
        setState((){
          if(dynamicCode != selectArr[0]['code']){
            dynamicCode = selectArr[0]['code'];
            repairProcName = null;
            repairProcCode = null;
            getSysAndProc();
          }
          typeName = selectItem['name'];
          typeCode = selectItem['code'];
          searchPackage();
        });
      },
    );
  }

  // 修制-修程
  void repairProcListSelect(){
    if(dynamicCode == null){
      showToast('请先选择机型');
    }else{
      ZjcCascadeTreePicker.show(context,
        data: repairProcList!,
        labelKey: 'name',
        valueKey: 'code',
        childrenKey: 'repairProcList',
        isShowSearch: false,
        title: "选择修程",
        clickCallBack: (selectItem, selectArr) {
          // print(selectArr);
          setState((){
            repairProcName = selectItem['name'];
            repairProcCode = selectItem['code'];
            getRepairMainNode();
            repairMainNodeName = null;
            repairMainNodeCode = null;
          });
          searchPackage();
        },
      );
    }
  }

  // 工序节点
  void repairMainNodeListSelect(){
    if(dynamicCode == null||repairProcCode == null){
      showToast('请先选择机型/修程');
    }else{
      ZjcCascadeTreePicker.show(context,
        data: repairMainNodeList!,
        labelKey: 'name',
        valueKey: 'code',
        isShowSearch: false,
        title: "选择工序节点",
        clickCallBack: (selectItem, selectArr) {
          // print(selectArr);
          setState((){
            repairMainNodeName = selectItem['name'];
            repairMainNodeCode = selectItem['code'];
          });
          searchPackage();
        },
      );
    }
  }

  // 查询
  void searchPackage(){
    if(typeCode != null&&repairMainNodeCode != null){
      getPackageUserList();
    }
  }

  //筛选表头 
  Widget buildItem(title,acqTitle,void Function() onTap) {
    double _screenWidth = MediaQuery.of(context).size.width - 20;
    dynamic _showTitle;
    if(title == null){
      _showTitle = acqTitle;
    }else{
      _showTitle = title;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
          child: DecoratedBox(
              decoration: BoxDecoration(border: Border(left: Divider.createBorderSide(context))),
              child: Container(
                margin: const EdgeInsets.only(left: 1.0, right: 1.0),
                width: (_screenWidth / 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              "$_showTitle",
                              style: TextStyle(
                                color: title != null?Colors.blueAccent:Colors.black,
                                fontSize: 15.0),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            )
                          ),
                          Container(
                            width: 0.0,
                          )
                        ],
                      ),
                    ),
                    if(title == null)
                      const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ))),
      onTap: () {
        onTap();
      },
    );
  }

  // 工位单元
  Widget packageItem(PackageUser pack, BuildContext context){
    return ExpansionTile(
      title: Text('${pack.station}'),
      // subtitle: const Text('点击展开物料列表'),
      children: <Widget>[
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          // 滚动方向上无边界约束
          shrinkWrap: true,
          itemCount: pack.packageUserDTOList!.length,
          itemBuilder: (context,index){
            return _itemWidget(pack.packageUserDTOList![index], context);
          },
          separatorBuilder: (context,index) => const Divider(height: .0,),
        )
      ],
    );
  }

  // 作业包单元
  Widget _itemWidget(PackageUserDTOList dto, BuildContext context){
    var cell = Padding(
      padding: const EdgeInsetsDirectional.all(5),
      child: Container(
        margin: const EdgeInsets.all(3),
        constraints: const BoxConstraints.tightFor(height: 145),
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
        child:InkWell(
          onTap: (){
            Navigator.of(context).pushNamed('muspecial',arguments: dto.packageEternalCode).then((value) => {
              searchPackage()
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                dense: true,
                // leading: ,
                title: Text("${dto.packageName}",style: const TextStyle(fontSize: 18.0),),
                // subtitle: Text("报修人：${item.reporterName}"),
                trailing:ElevatedButton(onPressed: (){
                  packageSelected = dto;
                  for (var element in userList) {
                    element['repairF'] = false;
                    element['assistantF'] = false;
                  }
                  // 调整用户表勾选情况-1
                  if(dto.workInstructPackageUserList![0].repairPersonnel != null){
                    List<String> list = dto.workInstructPackageUserList![0].repairPersonnel!.split(',');
                    for (var element in list) {
                      userList.firstWhere((e) => e['userId'] == int.parse(element))['repairF'] = true;
                    }
                  }
                  if(dto.workInstructPackageUserList![0].assistant != null){
                    List<String> list = dto.workInstructPackageUserList![0].assistant!.split(',');
                    for (var element in list) {
                      userList.firstWhere((e) => e['userId'] == int.parse(element))['assistantF'] = true;
                    }
                  }
                  Scaffold.of(context).openEndDrawer();
                }, child: const Icon(Icons.checklist_rtl_sharp)),
              ),
              ZjcFormInputCell(
                title: "主修",
                text: dto.workInstructPackageUserList![0].repairPersonnelName,
                hintText: "无数据",
                enabled: false,
                titleStyle: tileText(16.0),
              ),
              ZjcFormInputCell(
                title: "辅修",
                text: dto.workInstructPackageUserList![0].assistantName,
                hintText: "无数据",
                enabled: false,
                titleStyle: tileText(16.0),
              ),
            ],
          ),
          
        )
      ),
    );
    return cell;
  }

  Widget _main(BuildContext context){
    List<Widget> list = [_filter(),];
    if(packageUserList != null){
      for (int i = 0, c = packageUserList!.length; i < c; ++i) {
        list.add(packageItem(packageUserList![i],context));
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: list
    );
  }

  // 字体
  TextStyle tileText(val,{bold,col}){
    return TextStyle(
      fontSize: val,
      fontWeight: bold != null?FontWeight.bold : FontWeight.normal,
      color: col
    );
  }
}