import 'dart:developer';

import 'package:jcjx_phone/zjc_common/zjc_form/zjc_searchbar.dart';

import '../../index.dart';

class DispatchList extends StatefulWidget {
  const DispatchList({Key? key}) : super(key: key);

  @override
  State<DispatchList> createState() => _DispatchListState();
}

class _DispatchListState extends State<DispatchList> {

  // 列表尽头
  static const loadingTag = '##loading##';
  var _items = <JtMessage>[JtMessage()..code = loadingTag];
  // 翻页标志
  bool hasMore = true;
  int pageNum = 1;
  // 选中派工项参数
  List<String?> selectDispath = [];
  // 搜索栏数据
  String searchBarText = "";
  // 班组人员数据
  List<dynamic> userList = [];
  // var _scaffoldkey = new GlobalKey<ScaffoldState>();
  // 施修人编号
  int? repairPersonnel;
  int? assistant;

  //查询待派工
   void _queryEntryData() async{
    var data = await JtApi().getJtList(
      queryParameters: {
        'completeStatus':1,
        'pageNum':pageNum,
        'pageSize':10,
        'team': Global.profile.permissions?.user.dept?.deptId,
      }
    );

    if(data.rows!.isNotEmpty){
      for (var element in data.rows!) {
        element.selected = false;
      }
      setState(() {
        hasMore = data.rows!.length > 0 && data.rows!.length%10==0;
        _items.insertAll(_items.length - 1, data.rows!);
        pageNum++;
      });
    }else{
      hasMore = false;
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
        });
      }else{
        showToast("未能获取班组人员");
      }
    }catch(e){
      print("$e");
    }
  }

  @override
  void initState(){
    super.initState();
    getJtUsers();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key: _scaffoldkey,
      appBar: AppBar(
        title: const Text("工长派工"),
      ),
      body: _buildBody(),
      endDrawer: _repairDrawer(),
      persistentFooterButtons: [
        Text("已选中 ${selectDispath.length} 项",style: tileText(18.0),),
        Builder(builder: (context){
          return ElevatedButton.icon(onPressed: (){
            if(selectDispath.isEmpty){
              showToast("至少选择一项作业进行分配");
            }else{
              Scaffold.of(context).openEndDrawer();
            }
          }, icon: Icon(Icons.tram_outlined), label: Text('派工',style: tileText(18.0),));
        })
      ],
      // bottomSheet:_footer(),
    );
  }
  
  Widget _buildBody(){
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ZjcSearchBar(
            hintText: "请输入车号",
            inputCompletionCallBack:(value, isSubmitted) {
              searchBarText = value;
              search();
            },
          ),
          Container(
            alignment: Alignment.topCenter,
            height: (MediaQuery.of(context).size.height)*0.8,
            child: ListView.separated(
              itemCount: _items.length,
              itemBuilder: (context,index){
                if(_items[index].code == loadingTag){
                  //单次加载容量
                  if(hasMore){
                    // 请求请料表数据
                    _queryEntryData();
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0,)
                      ),
                    );
                  }else{
                    return Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Text("这个账号下已经没有待分配作业项了",
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    );
                  }
                }
                return _itemWidget(_items[index]);
              }, 
              separatorBuilder: (context,index) => const SizedBox(height: .0,), 
            )
          )
        ]
      ),
    );
  }

  // 搜索框查询
  void search(){
    setState(() {
      pageNum = 1;
      hasMore = true;
      _items = <JtMessage>[JtMessage()..code = loadingTag];
      selectDispath = [];
    });
  }

  // 刷新
  update(){
    setState(() {
      _items = <JtMessage>[JtMessage()..code = loadingTag];
      hasMore = true;
      pageNum = 1;
    });
  }

  // 数据模板
  Widget _itemWidget(JtMessage item) {
    var cell = Padding(
      padding: const EdgeInsetsDirectional.all(5),
      child: Container(
        margin: const EdgeInsets.all(3),
        constraints: const BoxConstraints.tightFor(height: 210),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              dense: true,
              leading: Checkbox(onChanged: (bool? value) { 
                setState(() {
                  item.selected = value;
                  if(value == true){
                    selectDispath.insert(0, item.code);
                  }else{
                    selectDispath.remove(selectDispath[selectDispath.indexOf(item.code)]);
                  }
                });
              }, value: item.selected,),
              title: Text("${item.trainType}-${item.trainNum}",style: TextStyle(fontSize: 18.0),),
              subtitle: Text("报修人：${item.reporterName}"),
              trailing:ElevatedButton(onPressed: (){
                Navigator.of(context).pushNamed('vehimageviewer',arguments: item);
              }, child: Icon(Icons.image)),
            ),
            ZjcFormInputCell(
              title: "故障现象",
              text: item.faultDescription,
              hintText: "无数据",
              maxLines: 2,
              maxLength: 200,
              enabled: false,
              titleStyle: tileText(16.0),
            ),
            ZjcFormInputCell(
              title: "加工方法",
              text: item.processMethodName,
              hintText: "无数据",
              enabled: false,
              titleStyle: tileText(16.0),
            ),
            ZjcFormInputCell(
              title: "检修作业来源",
              text: item.repairResourceName,
              hintText: "无数据",
              enabled: false,
              titleStyle: tileText(16.0),
            ),
          ],
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

  // 底部
  // Widget _footer(){
  //   return SafeArea(
  //     child: InkWell(
  //       onTap: (){
  //         _scaffoldkey.currentState?.openDrawer();
  //       },
  //       child: Container(
  //         alignment: Alignment.center,
  //         color: Colors.lightBlue[100],
  //         height: 50,
  //         child: const Text('派工（已勾选数量）', style: TextStyle(color: Colors.black,fontSize: 18)),
  //       ),
  //     )
  //   );
  // }

  // 照片查看
  void showPicDialog(url) async {
    SmartDialog.show(
      builder: (context){
        return Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Image(
            image: NetworkImage(
              "http://10.102.72.103:8080/fileserver/FileOperation/previewImage?url=$url",
              headers: {
                "Authorization":Global.profile.data!.access_token!,
              }
          ),)
        );
    });
  }

  Widget _repairDrawer(){
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
                  child: Text("${userList[index]['nickName']}"),
                ),
                Radio(
                value: userList[index]['userId'],
                activeColor: const Color.fromARGB(255, 59, 58, 58),
                groupValue: repairPersonnel,
                onChanged: (dynamic value) {
                  setState(() {
                    repairPersonnel = value!;
                  });
                }),
                Radio(
                value: userList[index]['userId'],
                activeColor: const Color.fromARGB(255, 59, 58, 58),
                groupValue: assistant,
                onChanged: (dynamic value) {
                  setState(() {
                    assistant = value!;
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

  Widget _drawerFooter(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        ElevatedButton(onPressed: (){
          setState((){
            assistant = null;
            repairPersonnel = null;
          });
        }, child: Text('重置'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(100, 40),
            backgroundColor: Color.fromRGBO(182, 182, 182, 1)
          ),),
        ElevatedButton(onPressed: () async {
          if(selectDispath.isEmpty){
            showToast('未选中派工项');
          }else if(repairPersonnel == null){
            showToast('请选择施修人');
          }else{
            List<Map<String,dynamic>> queryParameters = [];
            for (var element in selectDispath) {
              queryParameters.insert(0, {
                "code":element,
                "completeStatus":0,
                "repairPersonnel":repairPersonnel
              });
            }
            if(assistant != null){
              for (var element in queryParameters) {
                element['assistant'] = assistant;
              }
            }
            // log("$queryParameters");
            try{
              SmartDialog.showLoading();
              var submit = await JtApi().dispatchJt28(
                queryParametrs: queryParameters
              );
              if(submit['code'] != "S_T_S003"){
                showToast("${submit['data']}");
              }
            }on DioException catch(e){
              showToast('$e');
            }finally{
              SmartDialog.dismiss(status: SmartStatus.loading);
              search();
            }
          }
        }, child: Text('确认'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(100, 40),
          ),  
        )
      ],
    );
  }
}