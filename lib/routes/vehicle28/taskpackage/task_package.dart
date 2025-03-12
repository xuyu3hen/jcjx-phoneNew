
import '../../../index.dart';

class TaskPackage extends StatefulWidget{
  final String trainEntryCode;
  const TaskPackage(this.trainEntryCode,{Key? key}) : super(key: key);

  @override
  State<TaskPackage> createState() => _TaskPackageState();
}

class _TaskPackageState extends State<TaskPackage> {

  // 列表尽头
  // static const loadingTag = '##loading##';
  var _items = <IndividualTaskPackage>[];

  // 动力类型
  List<Map<String,dynamic>> dynamicList = [];
  String? dynamicCode;
  // 机型
  List<Map<String,dynamic>> jcTypeList = [];
  String? typeName;
  var logger = AppLogger.logger;

  // 个人作业包
  void getIndividualTaskPackage() async {
    SmartDialog.showLoading();
    _items = <IndividualTaskPackage>[];
    var r = await JtApi().getIndividualTaskPackage(
      queryParameters:{
        'trainEntryCode': widget.trainEntryCode,
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

  // 作业包回退
  Future cancelPersonalPackage(val) async {
    var r = await JtApi().cancelPersonalPackage(
      queryParameters: [val]
    );
    if(r.code == "S_F_S000"){
      showToast('领活已回退');
      return true;
    }else{
      showToast('领活回退失败');
    }
  }

  // AB端切换
  Future<int> updateWorkInstructPackage(val) async {
    logger.i(json.decode(json.encode(val)));
    var list = <Map<String,dynamic>>[];
    list.insert(0, json.decode(json.encode(val)));
    var r = await JtApi().updateWorkInstructPackage(
      queryParameters:list
    );
    if(r['message'] == "操作成功"&&r['code']== 200){
      logger.i('切换AB端成功');
    }else{
      showToast('切换AB端出现错误');
    }
    return r['code'];
  }

  @override
  void initState() {
    super.initState();
    getIndividualTaskPackage();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  // 列表
  Widget _buildBody(){
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

  // 数据模板
  Widget _itemWidget(IndividualTaskPackage item) {
    var cell = Padding(
      padding: const EdgeInsetsDirectional.all(5),
      child: Container(
        margin: const EdgeInsets.all(3),
        constraints: const BoxConstraints.tightFor(height: 109),
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
            if(item.wholePackage!&&item.progress == 0)...[
              ListTile(
                dense: true,
                leading: Text("${item.name}",style: const TextStyle(fontSize: 18.0),),
                title: Text("${item.station}",style: const TextStyle(fontSize: 16.0)),
                // subtitle: Text(""),
                trailing:ElevatedButton(onPressed: (){
                  changeABDialog(item);
                }, 
                child: Text(item.ends??'A/B',style: tileText(18.0,bold: FontWeight.bold,col: item.ends =='B'?Colors.orange:Colors.red),)),
              ),
            ]else if(item.wholePackage!)...[
              ListTile(
                dense: true,
                leading: Text("${item.name}",style: const TextStyle(fontSize: 18.0),),
                title: Text("${item.station}",style: const TextStyle(fontSize: 16.0)),
                // subtitle: Text(""),
                trailing:Text(item.ends??'A/B',style: tileText(18.0,bold: FontWeight.bold,col: item.ends =='B'?Colors.orange:Colors.red),),
              ),
            ]else...[
              ListTile(
                dense: true,
                leading: Text("${item.name}",style: const TextStyle(fontSize: 18.0),),
                title: Text("${item.station}",style: const TextStyle(fontSize: 16.0)),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('作业进度'),
                SizedBox(
                  height: 5,
                  width: 240,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Colors.blue),
                    value: item.progress == 0? 0 : (item.completeCount!/item.total!),
                  ),
                ),
                Text('${item.completeCount!}/${item.total!}')
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width)/2-8,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      if(item.progress != 0){
                        showToast('已进行过作业，无法退回作业包');
                      }else{
                        cancelPersonalPackage(item.code).then((value) => {
                          if(value == true){
                            getIndividualTaskPackage()
                          }
                        });
                      }
                    },
                    // 按钮样式
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.blueGrey[100]),
                      shape: const MaterialStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(bottomLeft:Radius.circular(10)),
                        ),
                      )
                    ),
                    child: const Text('取消领活'),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width)/2-8,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                    },
                    style: const ButtonStyle(
                      shape: MaterialStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(bottomRight:Radius.circular(10)),
                      ),
                      )
                    ),
                    child: const Text('继续作业'),
                  ),
                ),
              ],
            )
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
                      label: const Text('取消'),
                      icon:const Icon(Icons.close),
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.grey[200]))
                    ),
                    ElevatedButton.icon(
                      onPressed: (){
                        updateWorkInstructPackage(item).then((value){
                          SmartDialog.dismiss().then((e)=>getIndividualTaskPackage());
                        });
                      },
                      label: const Text('确定'),
                      icon:const Icon(Icons.system_security_update_good_sharp),
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
