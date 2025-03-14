
import '../index.dart';

class EntryTrainItem extends StatefulWidget {
  final TrainEntry trainentry;
  final Function updateList;
  EntryTrainItem(this.trainentry,this.updateList) :super(key: ValueKey(trainentry.code));

  @override
  State createState() => _EntryTrainItem();
}

class _EntryTrainItem extends State<EntryTrainItem> {

  final ImagePicker picker = ImagePicker();
  File? _image;
  
  // 油量/防溜
  String? imgtype;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0,left: 20.0,right: 20.0),
      child: Container(
        constraints: const BoxConstraints.tightFor(height: 150),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(2.0, 2.0),
              blurRadius: 4.0,
            )
          ]
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 0.0,bottom: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                dense: true,
                leading: Text(
                  "${widget.trainentry.typeName}-${widget.trainentry.trainNum}",
                  style: leadingStyle(18.0),
                ),
                // title: Text("${widget.trainentry.repairProcName}-${widget.trainentry.repairTimes}"),
                trailing: Text("${widget.trainentry.repairProcName}-${widget.trainentry.repairTimes}",style: leadingStyle(18.0),),
              ),
              const Divider(height: 0.0,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  dataText("机型",16.0),
                  dataText("车号",16.0),
                  dataText("入修时间",16.0),
                ],
              ),
              const Divider(height: 0.1,indent: 20.0,endIndent: 20.0,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  dataText("${widget.trainentry.typeName}",16.0),
                  dataText("${widget.trainentry.trainNum}",16.0),
                  dataText("${widget.trainentry.arrivePlatformTime}",16.0),
                ],
              ),
              const SizedBox(width: 200,height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if(widget.trainentry.antiSlipImage == null)...[
                    SizedBox(width: 170,height:30.0,child: ElevatedButton(onPressed: ()=>{uploadDialog("slip")}, child: const Text("上传防溜")),),
                  ]else...[
                    SizedBox(width: 170,height:30.0,child: ElevatedButton(onPressed: ()=>{showPicDialog(widget.trainentry.antiSlipImage)},style:ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green[200])), child: const Text("查看防溜"))),
                  ],
                  if(widget.trainentry.oilInfoImage == null)...[
                    SizedBox(width: 170,height:30.0,child: ElevatedButton(onPressed: ()=>{uploadDialog("oil")}, child: const Text("上传油量"))),
                  ]else...[
                    SizedBox(width: 170,height:30.0,child: ElevatedButton(onPressed: ()=>{showPicDialog(widget.trainentry.oilInfoImage)},style:ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green[200])), child: const Text("查看油量"))),
                  ]
                  
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  TextStyle leadingStyle(val){
    return TextStyle(
      fontSize: val,
      color: Colors.black,
    );
  }
  Text dataText(str,val){
    return Text(
      str,
      style: TextStyle(fontSize: val,color: Colors.black,),
    );
  }

  // 照片查看
  void showPicDialog(url) async {
    SmartDialog.show(
      builder: (context){
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Image(
            image: NetworkImage(
              "http://10.102.72.103:8080/fileserver/FileOperation/previewImage?url=$url",
              headers: {
                "Authorization":Global.profile.data!.access_token!,
              }
          ),)
        );
    });
  }
  
  // 上传照片弹窗
  void uploadDialog(str){
    imgtype = str;
    switchDialog(str);
  }

  void switchDialog(str){
    SmartDialog.show(
      clickMaskDismiss:false,
      usePenetrate:false,
      builder: (context) {
      return Container(
        height:330,
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child:
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              dataText(str == "slip"?"上传防溜":"上传油量",18.0),
              if(_image == null)
                InkWell(
                  child: Container(
                    constraints: const BoxConstraints.tightFor(width: 200,height: 200),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo)
                        ],
                      ),
                    ),
                  onTap: () => {
                    showBottomSheet(context)
                  },
                ),
              if(_image != null)
                Image.file(_image!,height: 200,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: 140,height:30.0,child: ElevatedButton(onPressed: ()=>{
                    if(_image != null){
                      SmartDialog.showLoading(),
                      if(str == "oil"){uploadOil(widget.trainentry.code),}
                      else{uploadSlip(widget.trainentry.code),},
                      SmartDialog.dismiss()
                    }else{
                      showToast("请先选择上传图像")
                    }
                  }, child: dataText("上传",18.0))),
                  SizedBox(width: 140,height:30.0,child: ElevatedButton(
                    onPressed: ()=>{
                      SmartDialog.dismiss(),
                      _image = null
                    }, child: dataText("取消",18.0))),
                ],
              )
            ],
          ),
      );
    });
  }

  // 图片来源选择支
  void showBottomSheet(BuildContext context){
    showModalBottomSheet(
      context: context, 
      builder: (BuildContext icontext){
        return buildBottomSheetWidget(icontext);
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
          const Divider(),

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
                height: 44,
                alignment: Alignment.center,
                child: const Text("取消"),
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
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 10,),
            Text(title)
          ],
        ),
      ),
    );
  }

  // 获取图片函数
  Future getImage(ImageSource isource) async {
    final pickedFile = await picker.pickImage(
      source: isource,
    );
    setState(() {
      if(pickedFile != null){
        _image = File(pickedFile.path);
        SmartDialog.dismiss();
        switchDialog(imgtype);
      }else{
        showToast("未获取图片");
      }
    });
  }

  // 上传防溜函数
  void uploadSlip(val) async {
    var r = await ProductApi().upSlipImg(
      queryParametrs: {
        "trainEntryCode":val
      },
      imagedata:File(_image!.path)
    );
    if(r == 200){
      showToast("上传成功");
      SmartDialog.dismiss();
      _image = null;
      widget.updateList.call();
    }
  }

  // 上传油量函数
  void uploadOil(val) async {
    var r = await ProductApi().uploadOilImg(
      queryParametrs: {
        "trainEntryCode":val
      },
      imagedata:File(_image!.path)
    );
    if(r == 200){
      showToast("上传成功");
      SmartDialog.dismiss();
      _image = null;
      widget.updateList.call();
    }
  }

}