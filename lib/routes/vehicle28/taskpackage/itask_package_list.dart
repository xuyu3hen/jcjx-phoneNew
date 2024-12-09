import 'dart:developer';

import 'package:jcjx_phone/index.dart';

class ITaskPackageList extends StatefulWidget{
  final String trainEntryCode;
  const ITaskPackageList(this.trainEntryCode,{Key? key}) : super(key: key);

  @override
  State<ITaskPackageList> createState() => _ITaskPackageListState();
  
}

class _ITaskPackageListState extends State<ITaskPackageList>{
  List<IndividualTaskPackage> procList = [];

  // 获取公共作业包
  void getCommonPackageList() async {
    var r = await JtApi().getCommonPackageList(
      queryParameters: {
        'trainEntryCode':widget.trainEntryCode
      }
    );
    if(r.code == "S_F_S000"&&r.data !=null){
      setState(() {
        procList =  r.data!;
      });
    }else{
      showToast('公共作业包获取失败');
    }
  }

  // 选择主修作业包(开工锁定)
  Future selectPersonalPackage(val) async {
    var r = await JtApi().selectPersonalPackage(
      queryParameters: [val]
    );
    if(r.code == "S_F_S000"){
      showToast('主修开工');
      return true;
    }else{
      showToast('主修开工失败');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(procList.isEmpty){
      getCommonPackageList();
    }
    return _body();
  }

  Widget _body(){
    List<Widget> list = [];
    if(procList.isNotEmpty){
      for (int i = 0, c = procList.length; i < c; ++i) {
        list.add(packageItem(procList[i]));
      }
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: list
      )
    );
  }

  // 修程单元
  Widget packageItem(IndividualTaskPackage item){
    List<Widget> list = [];
    if(procList.isNotEmpty){
      for (int i = 0, c = item.taskCertainPackageList!.length; i < c; ++i) {
        list.add(_itemWidget(item.taskCertainPackageList![i]));
      }
    }
    return Column(
      children: [
        if(item.executorId != null)...[
          ExpansionTile(
            title: Text('${item.name}',style: tileText(18.0),),
            subtitle: Text(item.station??""),
            trailing: ElevatedButton(onPressed: () {
              selectPersonalPackage(item.code).then((value) => {
                if(value == true){
                  getCommonPackageList()
                }
              });
            }, child: Text('主修认领')),
            collapsedBackgroundColor: Colors.blue[100],
            children: list
          ),
          const Divider(height: 1,)
        ]else...[
          ExpansionTile(
            title: Text('${item.name}',style: tileText(18.0),),
            subtitle: Text(item.station??""),
            collapsedBackgroundColor: Colors.blue[100],
            children: list
          ),
          const Divider(height: 1,)
        ]
      ],
    );
  }

  // 工序单元
  Widget _itemWidget(TaskCertainPackageList item){
    var cell = Padding(
      padding: const EdgeInsetsDirectional.all(5),
      child: Container(
        margin: const EdgeInsets.all(3),
        constraints: const BoxConstraints.tightFor(height: 60),
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
            Navigator.of(context).pushNamed('trainbynode',arguments: item).then((value) => {
              getCommonPackageList()
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                dense: true,
                // leading: ,
                title: Text("${item.name}",style: TextStyle(fontSize: 18.0),),
                // subtitle: Text("报修人：${item.reporterName}"),
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
}