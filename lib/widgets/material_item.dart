import '../index.dart';

class MaterialItem extends StatefulWidget {
  final MaterialStore materialSt;

  MaterialItem(this.materialSt) :super(key: ValueKey(materialSt.id));

  @override
  State createState() => _MaterialItem();
}

class _MaterialItem extends State<MaterialItem> {
  @override
  Widget build(BuildContext context) {
    var subtitle;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Material(
        color: Colors.white,
        shape: BorderDirectional(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: .5,
          ),
        ), 
        child: Padding(
          padding: const EdgeInsets.only(top: 0.0,bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                dense: true,
                leading: Text(widget.materialSt.materialName??''),
                // textScaleFactor字体缩放比例
                title: Text(widget.materialSt.materialCode??'',textScaleFactor: .9,),
                // 副标题
                subtitle: subtitle,
                trailing:  Text("数量：${widget.materialSt.num}"),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "批次号：${widget.materialSt.batchNum??''}",
                      style: TextStyle(
                        fontSize:15,
                        fontWeight: FontWeight.bold,
                        fontStyle: widget.materialSt.state == "1"
                                    ? FontStyle.italic:FontStyle.normal,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top:8,bottom: 12),
                      child: Text(widget.materialSt.supplierName??'',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                    )
                  ]
                ),
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
  //       Text("签收数量：${widget.materialSt.acceptNum}".padRight(paddingWidth)),
  //       ];

  //       if(widget.materialSt.isCompleted == '1'){
  //         children.add(const Text("已配料完成"));
  //       }
  //       return Row(children: children,);
  //     },),)
  //   );
  // }
}