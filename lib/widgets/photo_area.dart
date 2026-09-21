
import '../index.dart';

class PhotoArea extends StatefulWidget{
  final File? _image;

  PhotoArea(this._image,{Key? key}) :super(key: key);

  @override
  State createState() => _PhotoArea();
}

class _PhotoArea extends State<PhotoArea>{
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _pickedImage = widget._image;
  }

  @override
  Widget build(BuildContext context){
    if(_pickedImage == null) {
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
                  if(_pickedImage != null)
                    Image.file(_pickedImage!,width: 200,height: 200,),
                  if(_pickedImage == null)
                  const Icon(Icons.add_a_photo)
                ],
              ),
            ),
          onTap: () {
            photoBottomSheet();
          },
        );
    }else{
      return Image.file(_pickedImage!,width: 200,height: 200,);
    }
          
  }

  void photoBottomSheet(){
    showModalBottomSheet(
      context: context, 
      builder: (BuildContext context){
        return buildBottomSheetWidget(context);
      }
    );
  }

  Widget buildBottomSheetWidget(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        children: [
          buildItem('拍照',onTap:(){
            getImage(ImageSource.camera);
            Navigator.of(context).pop();
          }),
          const Divider(),

          buildItem('打开相册',onTap:(){
            getImage(ImageSource.gallery);
            Navigator.of(context).pop();
          }),

          Container(color: Colors.grey[300],height: 8,),

          InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                height: 44,
                alignment: Alignment.center,
                child: const Text('取消'),
              ),)
        ],
      ),
    );
  }

  Widget buildItem(String title,{String? imagePath,Function? onTap}){
    return InkWell(
      onTap: (){
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

  Future getImage(ImageSource isource) async {
    final pickedFile = await ImagePicker().pickImage(
      source: isource,
    );
    if(pickedFile != null){
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      SmartDialog.dismiss();
    }else{
      showToast('未获取图片');
    }
  }
}
