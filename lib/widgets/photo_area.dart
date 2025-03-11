


import '../index.dart';

class PhotoArea extends StatefulWidget{
  File? _image;

  PhotoArea(this._image,{Key? key}) :super(key: key);

  @override
  _PhotoArea createState() => _PhotoArea();
}

class _PhotoArea extends State<PhotoArea>{
  @override
  Widget build(BuildContext context){
    if(widget._image == null) {
      return InkWell(
          child: Container(
            constraints: const BoxConstraints.tightFor(width: 200,height: 200),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if(widget._image != null)
                    Container(
                      child: Image.file(widget._image!,width: 200,height: 200,),
                    ),
                  if(widget._image == null)
                  const Icon(Icons.add_a_photo)
                ],
              ),
            ),
          onTap: () {
            photoBottomSheet();
          },
        );
    }else{
      return Image.file(widget._image!,width: 200,height: 200,);
    }
          
  }

  // 
  // 图片来源选择支
  void photoBottomSheet(){
    showModalBottomSheet(
      context: context, 
      builder: (BuildContext context){
        return buildBottomSheetWidget(context);
      }
    );
  }

  // 选择支构筑
  Widget buildBottomSheetWidget(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        children: [
          buildItem("拍照",onTap:(){
            getImage(ImageSource.camera);
            Navigator.of(context).pop();
          }),
          //分割线
          Divider(),

          buildItem("打开相册",onTap:(){
            getImage(ImageSource.gallery);
            Navigator.of(context).pop();
          }),

          Container(color: Colors.grey[300],height: 8,),

          //取消按钮
          //添加个点击事件
          InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                child: Text("取消"),
                height: 44,
                alignment: Alignment.center,
              ),)
        ],
      ),
    );
  }

  // 选择支子单元
  Widget buildItem(String title,{String? imagePath,Function? onTap}){
    //添加点击事件
    return InkWell(
      //点击回调
      onTap: (){
        //关闭弹框
        // Navigator.of(context).pop();
        //外部回调
        if(onTap!=null){
          onTap();
        }
      },
      child: Container(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 10,),
            Text(title)
          ],
        ),
      ),
    );
  }

  // 获取图片函数
  Future getImage(ImageSource isource) async {
    final pickedFile = await ImagePicker().pickImage(
      source: isource,
    );
    if(pickedFile != null){
      setState(() {
        widget._image = File(pickedFile.path);
      });
      SmartDialog.dismiss();
    }else{
      showToast("未获取图片");
    }
  }
}