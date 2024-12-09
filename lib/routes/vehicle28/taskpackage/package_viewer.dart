import 'package:jcjx_phone/index.dart';
import 'package:jcjx_phone/zjc_common/widgets/zjc_top_tabbar.dart';

class PackageViewer extends StatefulWidget{
  const PackageViewer({super.key});

  @override
  State<PackageViewer> createState() => _PackageViewerState();
}

class _PackageViewerState extends State<PackageViewer>{
  late TrainEntryByNodeCode trainEntry;
  @override
  Widget build(BuildContext context) {
    trainEntry = ModalRoute.of(context)!.settings.arguments as TrainEntryByNodeCode;
    return ZjcTopTabBar(
      title: '${trainEntry.trainNum}-作业',
      tabModelArr: [
        ZjcTopTabBarModel(title: '公共作业包', widget: ITaskPackageList(trainEntry.code)),
        // 不合格项 范围需要过滤
        ZjcTopTabBarModel(title: '不合格项', widget: UnqualifiedList(trainEntry.code)),
        ZjcTopTabBarModel(title: '个人作业包', widget: TaskPackage(trainEntry.code)),
      ],
      // showCenterLine: true,
      isScrollable: false,
    );
  }
}