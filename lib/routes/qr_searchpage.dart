import '../index.dart';
import 'package:flutter_custom_dropdown/flutter_custom_dropdown.dart' as downmenu;
import '../config/filter_data.dart';
class QRsearchPage extends StatefulWidget{

  @override
  _QRsearchPage createState() => _QRsearchPage();
}

class _QRsearchPage extends State<QRsearchPage>{
  // 筛选器属性
  bool? showpackage;

  @override
  Widget build(BuildContext context){
    QRSearchMsg abd = ModalRoute.of(context)!.settings.arguments as QRSearchMsg;
    return Scaffold(
      appBar: AppBar(
        title: const Text("物料信息"),
      ),
      body: _buildBody(abd),
    );
  }

  Widget _buildBody(abd){
    // 一般件
    if(abd.type == 1){
      return Container(
        child: downmenu.DefaultDropdownMenuController(
          onSelected: ({int? menuIndex,dynamic data}){
            print("点击的筛选器顺序和内容：$menuIndex,$data");
            if(menuIndex == 0){
              // TODO：测试是否需要置于函数体内
              showpackage = (data[0])["value"];
              print("赋值$showpackage");
              setState(() {
                
              });
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Container(color: Colors.white, child: buildDropdownHeader()),
                  Expanded(child: _normalBody(abd)),
                ],
              ),
              Padding(padding: const EdgeInsets.only(top: 40), child: buildDropdownMenu(context))
            ],
            ),
        ),
      );
    }else{
      return RotableItem(abd.reveal.data);
    }
  }

  Widget _normalBody(abd){
    // reveal是包括code和msg的返回体
    Package package = abd.reveal.data;
    var children = <Widget>[
      Text("二维码code:${package.code}"),
    ];
    if(package.materialList != []){
      children.add(
        ExpansionTile(
          title: const Text('物料列表'),
          subtitle: const Text('点击展开物料列表'),
          children: <Widget>[
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              // 滚动方向上无边界约束
              shrinkWrap: true,
              itemCount: package.materialList!.length,
              itemBuilder: (context,index){
                return MaterialItem(package.materialList![index]);
              },
              separatorBuilder: (context,index) => const Divider(height: .0,),
            )
          ],
        )
      );
    }

    if(package.packageList != null){
      // print(package?.packageList?[1].materialList?[0].materialName);
      children.add(
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          // 滚动方向上无边界约束
          shrinkWrap: true,
          itemCount: package.packageList!.length,
          itemBuilder: (context,index){
            if(showpackage == false && package.packageList![index].materialList!.isEmpty){
              return Container();
            }else{
              return ExpansionTile(
                title: Text('包装编码：${package.packageList![index].code??''}'),
                subtitle: Text(package.packageList![index].materialList!.isEmpty? '空包装': '点击展开包装内容'),
                children: <Widget>[
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    // 滚动方向上无边界约束
                    shrinkWrap: true,
                    itemCount: package.packageList![index].materialList!.length,
                    itemBuilder: (context,index2){
                      return MaterialItem(package.packageList![index].materialList![index2]);
                    },
                    separatorBuilder: (context,index) => const Divider(height: .0,),
                  )
                ],
              );
            }
          },
          separatorBuilder: (context,index) => const Divider(height: 20,color:Color.fromARGB(255, 15, 238, 108),),
        )
      );

    }

    return SingleChildScrollView(child: Column(children: children),);
  }


  downmenu.DropdownHeader buildDropdownHeader({downmenu.DropdownMenuHeadTapCallback? onTap}) {
    return downmenu.DropdownHeader(
      isSideline: false,
      onTap: onTap,
      titles: ['是否显示空包装'],
      selectIsChangingColor: true,
      // specialModules: [1],
      ///特殊模块,选中数据只亮起,不需要更改头部title,下标为1
    );
  }

  downmenu.DropdownMenu buildDropdownMenu(BuildContext context){
    return downmenu.DropdownMenu(menus: [
      downmenu.DropdownMenuBuilder(
        builder: (BuildContext context){
          return downmenu.DropdownListMenu(
              // 默认选项
              selectedIndex: FilterData.packageFlag[0],
              // 是否带按钮
              isOperatingButton: false,
              // 是否多选
              isMultiple: false,
              keyWords: "key",
              data: FilterData.packageFlag,
              itemBuilder: downmenu.buildCheckItem,
          );
        },
        // 最大高度
        screenHeight: MediaQuery.of(context).size.height,
        // 内容高度
        draughtHeight: 60 * 1.8,
        // 距离屏幕底部高度
        bottomSpacingHeight: 168.0)
    ]);
  }
}

class QRSearchMsg{
  final int? type;
  final dynamic reveal;

  QRSearchMsg(this.type,this.reveal);
}