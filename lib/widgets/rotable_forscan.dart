import '../index.dart';

class RotableItem extends StatefulWidget {
  final Rotable rotableSt;

  RotableItem(this.rotableSt) :super(key: ValueKey(rotableSt.id));

  @override
  _RotableItem createState() => _RotableItem();
}

class _RotableItem extends State<RotableItem> {
  @override
  Widget build(BuildContext context) {
    // var subtitle;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Material(
        color: Colors.white,
        shape: BorderDirectional(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: .9,
          ),
        ), 
        child: Padding(
          padding: const EdgeInsets.only(top: 0.0,bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                dense: true,
                shape:Border(bottom: BorderSide(color: Colors.blue.shade200,width: 3)),
                // shape: StadiumBorder(side: BorderSide(color: Colors.blue.shade200,width: 1)),
                leading: Text(
                  '周转件名称：${widget.rotableSt.materialName??''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 221, 44, 0)
                  ),
                ),
                // textScaleFactor字体缩放比例
                // title: Text(widget.rotableSt.materialCode??'',textScaleFactor: .9,),
                // 副标题
                // subtitle: subtitle,
                trailing:  Text(
                  "单位：${widget.rotableSt.unitNum}",
                  style: TextStyle(fontSize: 18,fontStyle: FontStyle.italic),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top:8.0,bottom: 8.0),
                          child: Text("配件分类：${widget.rotableSt.capitalType == 1 ?'普通件':'高价件'}",style:commonText(16.0,col: Colors.indigo)),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 5.0),
                          child: Text("序列号：${widget.rotableSt.serialNum??''}",style:commonText(16.0,col: Colors.indigo)),
                        ),
                        Text("规格型号：${widget.rotableSt.materialModel??''}"),
                        Text("产品名称：${widget.rotableSt.producerName??''}"),
                        Text("产品编号：${widget.rotableSt.productNum??''}"),
                        Text("固资编号：${widget.rotableSt.capitalNum??''}"),
                        Text("生产日期：${widget.rotableSt.productionDate??''}"),
                        Text("入库签收日期：${widget.rotableSt.putinQualitySignDate??''}"),
                        Text("合格证签发日期：${widget.rotableSt.qualityCertificationDate??''}"),
                        Text("合格证位置：${widget.rotableSt.qualityCertificationLocation??''}"),
                        Text("配件状态：${widget.rotableSt.materialState == 1? '合格品': (widget.rotableSt.materialState == 2?'待检修':'检修品')}"),
                        Text("配件状态补充：${widget.rotableSt.materialStateDetail??''}"),
                        Text("修程与检修日期：${widget.rotableSt.repairCycle??''}"),
                        Text("修改日期：${widget.rotableSt.lastMaintenanceDate??''}"),
                        Text("创建日期：${widget.rotableSt.createDatetime??''}"),
                        Text("维护周期：${widget.rotableSt.maintenanceCycle??''}"),
                        Text("报废时间：${widget.rotableSt.expirationDate??''}"),
                        Text("适用车型：${widget.rotableSt.trainModels??''}"),
                        Text("最后维护日：${widget.rotableSt.lastMaintenanceDate??''}"),
                        Text("储存状态：${widget.rotableSt.storeState == 1 ?'在库':
                        (widget.rotableSt.storeState == 2 ? '配送': 
                          (widget.rotableSt.storeState == 3 ? '报废':
                            (widget.rotableSt.storeState == 4 ? '装车': '返厂'
                            )
                          )
                        )
                        }"),
                        Text("装车位置：${widget.rotableSt.truckLocation??'未装车'}"),
                        Text("存放点备注：${widget.rotableSt.locationRemark??''}"),
                        Text("配件来源：${widget.rotableSt.putinSource??''}"),
                        Text("橡胶节点日期：${widget.rotableSt.rubberNodeDate??''}"),
                        Text("仓库名称：${widget.rotableSt.storePlaceName??''}"),
                        Text("存放地点：${widget.rotableSt.storeLocationName??''}"),
                        Text("所属车间：${widget.rotableSt.rootStorePlaceName??''}"),
                        Text("备注：${widget.rotableSt.remark??''}"),
                        // Padding(
                        //   padding: const EdgeInsets.only(top:8,bottom: 12),
                        //   child: Text('供货商名：${widget.rotableSt.supplierName??''}',
                        //               style: TextStyle(
                        //                 color: Colors.grey[700],
                        //               ),
                        //             ),
                        // ),
                        
                      ]
                    ),
                  ],
                )
                
              ),
              // _buildBottom()
            ]
          ),
        ),
      ),
    );
  }

  // 卡片底部
  // Widget _buildBottom(){
  //   const paddingWidth = 10;
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: Material(child: Builder(builder: (context) {
  //       var children = <Widget>[
  //       Text("签收数量：${widget.rotableSt.acceptNum}".padRight(paddingWidth)),
  //       ];

  //       if(widget.rotableSt.isCompleted == '1'){
  //         children.add(const Text("已配料完成"));
  //       }
  //       return Row(children: children,);
  //     },),)
  //   );
  // }

  TextStyle commonText(val,{col}){
    return TextStyle(
      fontSize: val,
      fontWeight: FontWeight.bold,
      color: col
    );
  }
}