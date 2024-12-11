import '../../index.dart';
import 'package:flutter/material.dart';

class TaskPackageDetailsPage extends StatelessWidget {
    final dynamic package;

    TaskPackageDetailsPage({required this.package});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('作业包详情'),
            ),
            body: ListView.builder(
                itemCount: package.taskCertainPackageList.length,
                itemBuilder: (context, index) {
                    final taskPackage = package.taskCertainPackageList[index];
                    return Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.blue,
                                width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    '${taskPackage.name}',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                    ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                    '风险等级: ${taskPackage.riskLevel?? '无'}', // 假设taskPackage里有riskLevel字段来表示风险等级，若没有则显示'无'
                                    style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 8),
                                Text(
                                    '状态: ${taskPackage.complete?? '未知'}', // 假设taskPackage里有status字段来表示状态，若没有则显示'未知'
                                    style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 16),
                                ListTile(
                                    title: Text('点击查看作业内容'),
                                    onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => TaskContentDetailsPage(
                                                    taskInstructContentList: taskPackage.taskInstructContentList, // 传递当前作业项对应的作业内容列表
                                                ),
                                            ),
                                        );
                                    },
                                ),
                            ],
                        ),
                    );
                },
            ),
        );
    }
}