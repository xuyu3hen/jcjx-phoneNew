import '../../index.dart';

class TaskPackageDetailsPage extends StatelessWidget {
  final dynamic package;

  TaskPackageDetailsPage({required this.package});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('作业项点'),
      ),
      body: ListView.builder(
        itemCount: package.taskCertainPackageList.length,
        itemBuilder: (context, index) {
          final taskPackage = package.taskCertainPackageList[index];
          return ListTile(
            title: Text('${taskPackage.name}'),
          );
        },
      ),
    );
  }
}