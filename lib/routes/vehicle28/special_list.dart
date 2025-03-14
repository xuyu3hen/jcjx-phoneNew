import 'package:jcjx_phone/index.dart';

import '../../zjc_common/zjc_form/zjc_searchbar.dart';

class SpecialList extends StatefulWidget {
  const SpecialList({super.key});

    @override
  State<SpecialList> createState() => _SpecialListState();
}

class _SpecialListState extends State<SpecialList> {
  // 列表尽头
  static const loadingTag = '##loading##';
  var _items = <JtMessage>[JtMessage()..code = loadingTag];
  // 翻页标志
  bool hasMore = true;
  int pageNum = 1;
  // 搜索栏数据
  String searchBarText = "";

  @override
  void initState(){
    super.initState();
  }

  //查询待派工
   void _queryEntryData() async{
    var data = await JtApi().getJtList(
      queryParameters: {
        'completeStatus':3,
        'pageNum':pageNum,
        'pageSize':10,
        'specialInspectionPersonnel': Global.profile.permissions?.user.userId,
      }
    );

    if(data.rows!.isNotEmpty){
      for (var element in data.rows!) {
        element.selected = false;
      }
      setState(() {
        hasMore = data.rows!.isNotEmpty && data.rows!.length%10==0;
        _items.insertAll(_items.length - 1, data.rows!);
        pageNum++;
      });
    }else{
      setState(() {
        hasMore = false;
      });
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("待专检列表"),
      ),
      // resizeToAvoidBottomInset: false,
      body: _buildBody(),
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
                      child: const SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0,)
                      ),
                    );
                  }else{
                    return Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Text("没有更多待处理的作业内容了",
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
        child:InkWell(
          onTap: (){
            Navigator.of(context).pushNamed('special',arguments: item).then((value) => {
              search()
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                dense: true,
                // leading: ,
                title: Text("${item.trainType}-${item.trainNum}",style: const TextStyle(fontSize: 18.0),),
                subtitle: Text("报修人：${item.reporterName}"),
                trailing:ElevatedButton(onPressed: (){
                  Navigator.of(context).pushNamed('vehimageviewer',arguments: item);
                }, child: const Icon(Icons.image)),
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
                title: "专检人",
                text: item.specialName,
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
}