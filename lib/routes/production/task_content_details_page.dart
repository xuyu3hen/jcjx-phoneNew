import 'package:flutter/material.dart';

class TaskContentDetailsPage extends StatelessWidget {
  final List<dynamic>? taskInstructContentList;

  TaskContentDetailsPage({required this.taskInstructContentList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('作业内容详情'),
      ),
      body: ListView.separated(
        itemCount: taskInstructContentList!.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          color: Colors.grey.shade300,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final contentItem = taskInstructContentList?[index];
          return ListTile(
            title: Text(
                '${contentItem.name?? ''}-${contentItem.workContent?? ''}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                ),
            ),
          );
        },
      ),
    );
  }
}