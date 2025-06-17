
import '../../index.dart';

class JtRepairPage extends StatefulWidget {
  const JtRepairPage({Key? key}) : super(key: key);
  @override
  State<JtRepairPage> createState() => _JtRepairPageState();
}

class _JtRepairPageState extends State<JtRepairPage> {
    @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    //展示对应机统28信息
    return Scaffold(
      appBar: AppBar(
        title: const Text('机修'),
      ),
      body: const Center(
        child: Text('机修'),
      ),
    );
  }
}