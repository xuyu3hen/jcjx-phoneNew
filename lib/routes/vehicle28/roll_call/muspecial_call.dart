import 'package:jcjx_phone/index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_empty_view.dart';

class MuSpecialCall extends StatefulWidget{
  const MuSpecialCall({super.key});

  @override
  State<MuSpecialCall> createState() => _MuSpecialCallState();
}

class _MuSpecialCallState extends State<MuSpecialCall>{

  List<WorkInstructPackageUserList> workInstructList = [];
  late String packageEternalCode;
  WorkInstructPackageUserList? riskSelected;
  // 互检列表
  List<dynamic> mutualList = [];
  // 专检列表
  List<dynamic> specialList = [];

  var logger = AppLogger.logger;

  // 获取作业项
  void getworkInstructList() async {
    var r = await JtApi().getworkInstructPackageUser(
      queryParameters: {
        'packageEternalCode':packageEternalCode
      }
    );
    if(r != []){
      setState(() {
        workInstructList = r;
      });
    }else{
      showToast('作业项获取出错');
    }
  }

  // 获取专互检人员列表
  void getCheckList(val) async {
    try {
      var r = await JtApi().getCheckList(queryParameters: {'riskLevel': val});
      setState(() {
        mutualList = r['互检'];
        specialList = r['专检'];
        for (var element in mutualList) {
          element['select'] = false;
        }
        for (var element in specialList) {
          element['select'] = false;
        }
      });
    } catch (e) {
      logger.e("$e");
      showToast("获取专互检人员表失败");
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    packageEternalCode = ModalRoute.of(context)!.settings.arguments as String;
    if(workInstructList.isEmpty){
      getworkInstructList();
    }
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
    // List<Widget> list = [];
    // if(workInstructList != []){
    //   for (int i = 0, c = workInstructList.length; i < c; ++i) {
    //     list.add(packageItem(workInstructList[i],context));
    //   }
    // }
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            alignment: Alignment.topCenter,
            height: (MediaQuery.of(context).size.height)*0.9,
            child: ListView.separated(
              itemCount: workInstructList.length,
              itemBuilder: (context,index){
                return packageItem(workInstructList[index],context);
              }, 
              separatorBuilder: (context,index) => const SizedBox(height: .0,), 
            )
          )
        ]
      ),
    );
  }

  Widget packageItem(WorkInstructPackageUserList wip,BuildContext context){
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
            if(riskSelected != null){
              if(riskSelected!.riskLevel != wip.riskLevel){
                getCheckList(wip.riskLevel);
                riskSelected = wip;
              }
            }else{
              riskSelected = wip;
              getCheckList(wip.riskLevel);
            }
            // 调整已勾选
            if(wip.mutualInspectionPersonnel != null){
              List<String> list = wip.mutualInspectionPersonnel.split(',');
              for (var element in list) {
                mutualList.firstWhere((e) => e['userId'] == int.parse(element))['select'] = true;
              }
            }
            if(wip.specialInspectionPersonnel != null){
              List<String> list = wip.specialInspectionPersonnel.split(',');
              for (var element in list) {
                specialList.firstWhere((e) => e['userId'] == int.parse(element))['select'] = true;
              }
            }
            Scaffold.of(context).openEndDrawer();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                dense: true,
                // leading: ,
                title: Text("${wip.name}",style: const TextStyle(fontSize: 16.0),),
                // subtitle: Text("报修人：${item.reporterName}"),
                trailing:Text("${wip.riskLevel}",style: const TextStyle(fontSize: 18.0))
              ),
              ZjcFormInputCell(
                title: "互检",
                text: wip.mutualPersonnelName,
                hintText: "无数据",
                enabled: false,
                titleStyle: tileText(16.0),
              ),
              ZjcFormInputCell(
                title: "专检",
                text: wip.specialPersonnelName,
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

  // 字体
  TextStyle tileText(val,{bold,col}){
    return TextStyle(
      fontSize: val,
      fontWeight: bold != null?FontWeight.bold : FontWeight.normal,
      color: col
    );
  }

  // 侧边人员表
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

  // 侧边头
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
                Text('互检',style: tileText(20.0,bold: true),),
                Text('专检',style: tileText(20.0,bold: true),)
              ]),
          ),
        );
      }
    );
  }

  // 侧边主体
  Widget _buildMenus() {
    if(mutualList.isEmpty&&specialList.isEmpty){
      return const ZjcEmptyView(text:"请选择作业项");
    }
    return Consumer<UserModel>(
      builder: (BuildContext context,UserModel userModel,Widget? child){
        return ListView.separated(
          itemCount: mutualList.length > specialList.length ? mutualList.length : specialList.length,
          itemBuilder: (context,index){
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:<Widget>[
                if(index < mutualList.length)...[
                  Container(
                    // 位置待调整,可能因分辨率错位
                    margin: const EdgeInsets.only(bottom: 15),
                    width: MediaQuery.of(context).size.width*0.35,
                    height: 40.0,
                    child: CheckboxListTile(
                    title: Text(mutualList[index]['nickName'],style: tileText(18.0),),
                    value: mutualList[index]['select'],
                    activeColor: const Color.fromARGB(255, 59, 58, 58),
                    onChanged: (dynamic value) {
                      setState(() {
                        mutualList[index]['select'] = value;
                      });
                  }),
                  )
                  
                ]else...[
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.35,
                    height: 40.0,
                  )
                ],
                if(index < specialList.length)...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    width: MediaQuery.of(context).size.width*0.35,
                    height: 40.0,
                    child: CheckboxListTile(
                    title: Text(mutualList[index]['nickName'],style: tileText(18.0),),
                    value: specialList[index]['select'],
                    activeColor: const Color.fromARGB(255, 59, 58, 58),
                    onChanged: (dynamic value) {
                      setState(() {
                        specialList[index]['select'] = value;
                      });
                  }),
                  )
                  
                ]else...[
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.35,
                    height: 40.0,
                  )
                ]
              ] 
            );
          },
          separatorBuilder: (context,index) => MediaQuery.removePadding(context: context,child: const Divider(height: 0.1,color:Colors.blue,)), 
        );
      }
    );
  }

  // 侧边底部按钮
  Widget _drawerFooter(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        ElevatedButton(onPressed: (){
          setState((){
            for (var element in mutualList) {
              element['select'] = false;
            }
            for (var element in specialList) {
              element['select'] = false;
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
              List muList = mutualList.where((element) => element['select'] == true).toList();
              List spList = specialList.where((element) => element['select'] == true).toList();
              String muStr = "";String muNameStr = "";
              String spStr = "";String spNameStr = "";
              // 数组指定属性拼接
              muStr = muList.map((e){return (e['userId']).toString();}).join(',');
              muNameStr = muList.map((e){return (e['nickName']).toString();}).join(',');
              spStr = spList.map((e){return (e['userId']).toString();}).join(',');
              spNameStr = spList.map((e){return (e['nickName']).toString();}).join(',');
              
              riskSelected!.mutualInspectionPersonnel = muStr;
              riskSelected!.mutualPersonnelName = muNameStr;
              riskSelected!.specialInspectionPersonnel = spStr;
              riskSelected!.specialPersonnelName = spNameStr;
              // for(var e in riskSelected){
              //   e.repairPersonnel = repairStr;
              //   e.repairPersonnelName = repairNameStr;
              //   e.assistant = asStr;
              //   e.assistantName = asNameStr;
              // }

              // list转mapList,不转接口报500
              var list = <Map<String,dynamic>>[];
              // list = packageSelected!.workInstructPackageUserList!.map((e){
              //   return e.toJson();
              //   }).toList();
              list.add(riskSelected!.toJson());
              
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
              getworkInstructList();
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
}