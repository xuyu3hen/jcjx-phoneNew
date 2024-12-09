
import '../index.dart';
import 'package:badges/badges.dart' as badges;

class FeatureContainer extends StatefulWidget{
  final Icon _icon;
  final Function pressFun;
  final String text;
  final double? width;
  final double? height;
  final int? num;

  FeatureContainer(this._icon,this.pressFun,this.text,{this.width,this.height,this.num}) :super(key: ValueKey(text));

  @override
  _FeatureContainer createState() => _FeatureContainer();
}

class _FeatureContainer extends State<FeatureContainer>{
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => widget.pressFun.call(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            badges.Badge(
              position: badges.BadgePosition.topEnd(top: -10,end: -10),
              // 控制显示红点
              showBadge: (widget.num != null && widget.num != 0),
              badgeStyle: badges.BadgeStyle(
                badgeColor: Colors.lightBlue.shade200
              ),
              badgeAnimation:const badges.BadgeAnimation.fade(
                animationDuration: Duration(seconds: 1),
                colorChangeAnimationDuration: Duration(seconds: 1),
                loopAnimation: false,
                curve: Curves.fastOutSlowIn,
                colorChangeAnimationCurve: Curves.easeInCubic,
              ),
              badgeContent: Text("${widget.num}",style: TextStyle(fontSize: 18),),
              child: 
              Container(
                constraints: BoxConstraints.tightFor(width: (widget.width!)/6,height: (widget.width!)/6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      offset: Offset(2.0, 2.0),
                      blurRadius: 4.0,
                    )
                  ]
                  ),
                child:IconButton(
                  icon: widget._icon,
                  iconSize: (widget.height!)/14.6,
                  color: Colors.black45,
                  onPressed: () => widget.pressFun.call(),
                ),
              ),
            ),
            const SizedBox(width: 0,height: 3,),
            Text(widget.text)
          ],
        )
      );
  }

}