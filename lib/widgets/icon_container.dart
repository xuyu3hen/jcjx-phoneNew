import 'dart:ffi';

import '../index.dart';

class IconContainer extends StatefulWidget{
  final String _image;
  final Function pressFun;
  final String text;
  double? width;
  double? height;

  IconContainer(this._image,this.pressFun,this.text,{this.width,this.height}) :super(key: ValueKey(text));

  @override
  State createState() => _IconContainer();
}

class _IconContainer extends State<IconContainer>{
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => widget.pressFun.call(),
      child: Container(
        constraints: BoxConstraints.tightFor(width: widget.width!/2.5,height: widget.height!/5),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/${widget._image}"),
            Text(widget.text,style: TextStyle(fontSize: widget.height!/50),),
          ],
        ),
      ),
    );
  }

}