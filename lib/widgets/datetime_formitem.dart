import '../index.dart';
class DatetimeFormitem extends StatefulWidget {
  DatetimeFormitem({
    super.key,
    required this.type,
    required this.datetime,
    required this.title,
  });

  final DateTimePickerType type;
  DateTime? datetime;
  String title;

  @override
  State<DatetimeFormitem> createState() => _DatetimeFormitemState();
}

class _DatetimeFormitemState extends State<DatetimeFormitem> {
  DateTime d = DateTime.now();

  void update(DateTime date) {
    setState(() {
      widget.datetime = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final result = await showBoardDateTimePicker(
            context: context,
            pickerType: DateTimePickerType.datetime,
          );
          if (result != null) {
         
            update(result);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Material(
                color: color,
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 36,
                  width: 36,
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  BoardDateFormat(format).format(widget.datetime!),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // String get title {
  //   switch (widget.type) {
  //     case DateTimePickerType.date:
  //       return 'Date';
  //     case DateTimePickerType.datetime:
  //       return 'DateTime';
  //     case DateTimePickerType.time:
  //       return 'Time';
  //   }
  // }

  IconData get icon {
    switch (widget.type) {
      case DateTimePickerType.date:
        return Icons.date_range_rounded;
      case DateTimePickerType.datetime:
        return Icons.date_range_rounded;
      case DateTimePickerType.time:
        return Icons.schedule_rounded;
    }
  }

  Color get color {
    switch (widget.type) {
      case DateTimePickerType.date:
        return Colors.blue;
      case DateTimePickerType.datetime:
        return Colors.orange;
      case DateTimePickerType.time:
        return Colors.pink;
    }
  }

  String get format {
    switch (widget.type) {
      case DateTimePickerType.date:
        return 'yyyy/MM/dd';
      case DateTimePickerType.datetime:
        return 'yyyy/MM/dd HH:mm';
      case DateTimePickerType.time:
        return 'HH:mm';
    }
  }
}
