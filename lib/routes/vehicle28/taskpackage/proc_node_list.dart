import 'dart:developer';

import 'package:jcjx_phone/index.dart';

class ProcNodeList extends StatefulWidget{
  const ProcNodeList({super.key});

  @override
  State<ProcNodeList> createState() => _ProcNodeListState();
  
}

class _ProcNodeListState extends State<ProcNodeList>{
  List<RepairProcAndNode> procList = [];
  
  // 获取修程-工序节点
  void getProcessingMainNodeAndProc() async {
    var r = await JtApi().getProcessingMainNodeAndProc(
    );
    if(r['code'] == "S_F_S000"){
      setState(() {
        procList =  r['data'].map<RepairProcAndNode>((e) => RepairProcAndNode.fromJson(e)).toList();
      });
    }else{
      showToast('工序节点获取失败');
    }
  }

  @override
  void initState() {
    super.initState();
    getProcessingMainNodeAndProc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("进行中工序"),
      ),
      // 打开侧边栏需要传递更低一级context
      body: _body(),
    );
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
  Widget packageItem(RepairProcAndNode rpan){
    return Column(
      children: [
        ExpansionTile(
          title: Text('${rpan.name}',style: tileText(18.0),),
          subtitle: Text(rpan.remark??""),
          initiallyExpanded: true,
          collapsedBackgroundColor: Colors.blue[100],
          children: <Widget>[
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              // 滚动方向上无边界约束
              shrinkWrap: true,
              itemCount: rpan.repairMainNodeList!.length,
              itemBuilder: (context,index){
                return _itemWidget(rpan.repairMainNodeList![index]);
              },
              separatorBuilder: (context,index) => const Divider(height: .0,),
            )
          ],
        ),
        Divider(height: 1,)
      ],
    );
  }

  // 工序单元
  Widget _itemWidget(RepairMainNodeList rmnl){
    var cell = Padding(
      padding: const EdgeInsetsDirectional.all(5),
      child: Container(
        margin: const EdgeInsets.all(3),
        constraints: const BoxConstraints.tightFor(height: 55),
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
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                dense: true,
                // leading: ,
                title: Text("${rmnl.name}",style: TextStyle(fontSize: 18.0),),
                // subtitle: Text("报修人：${item.reporterName}"),
                trailing:ElevatedButton(onPressed: (){
                  Navigator.of(context).pushNamed('trainbynode',arguments: rmnl.code).then((value) => {
                    getProcessingMainNodeAndProc()
                  });
                }, child: Icon(Icons.train_outlined)),
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