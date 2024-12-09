
import '../index.dart';

/// TODO : 元数据
/// TODO : title字段专门给回显值留下的
class FilterData{

  static List<Map<String,dynamic>>  packageFlag = [
    {'key': '0','value' : true,'title' : '显示空包装' },
    {'key': '1','value' : false,'title' : '不显示空包装' },
  ];

  static List<Map<String,dynamic>>  truckCompleteFlag = [
    {'key': '0','value' : false,'title' : '不显示已上车项' },
    {'key': '1','value' : true,'title' : '显示已上车项' },
  ];

  static List<Map<String,dynamic>>  orgName= [
    {'key': '0','value' : '动车转向架车间','title' : '动车转向架车间' },
    {'key': '1','value' : '动车检修车间','title' : '动车检修车间' },
  ];

  static List<Map<String,dynamic>>  completeStatusList= [
    {'value' : 0,'label' : '自检自修' },
    {'value' : 1,'label' : '工长派工' },
  ];

  static List<Map<String,dynamic>>  mutualStatusList= [
    {'value' : 0,'label' : '不通过' },
    {'value' : 1,'label' : '通过' },
  ];


}