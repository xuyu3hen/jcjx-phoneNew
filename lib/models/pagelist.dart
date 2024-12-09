import 'package:json_annotation/json_annotation.dart';
part 'pagelist.g.dart';

@JsonSerializable()
class PageList {

  PageList({
        this.total,
        // required this.list,
        this.pageNum,
        this.pageSize,
        this.size,
        this.startRow,
        this.endRow,
        this.pages,
        this.prePage,
        this.nextPage,
        this.isFirstPage,
        this.isLastPage,
        this.hasPreviousPage,
        this.hasNextPage,
        this.navigatePages,
        this.navigatepageNums,
        this.navigateFirstPage,
        this.navigateLastPage,
  });

  int? total;
  // List<DeliveryApply> list;
  String? materialName;
  int? pageNum;
  int? pageSize;
  int? size;
  int? startRow;
  int? endRow;
  int? pages;
  int? prePage;
  int? nextPage;
  bool? isFirstPage;
  bool? isLastPage;
  bool? hasPreviousPage;
  bool? hasNextPage;
  int? navigatePages;
  List<int>? navigatepageNums;
  int? navigateFirstPage;
  int? navigateLastPage;


  factory PageList.fromJson(Map<String,dynamic> json) => _$PageListFromJson(json);
  Map<String, dynamic> toJson() => _$PageListToJson(this);
}
