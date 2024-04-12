import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// class MultipleScrollPicker extends StatefulWidget {
//   @override
//   _MultipleScrollPickerState createState() => _MultipleScrollPickerState();
// }

// class _MultipleScrollPickerState extends State<MultipleScrollPicker> {
//   int _selectedHour = 0;
//   int _selectedMinute = 0;
//   final List<int> hours = List.generate(24, (index) => index);
//   final List<int> minutes = List.generate(60, (index) => index);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         // 小时选择器
//         Container(
//           height: 200,
//           width: MediaQuery.of(context).size.width / 3,
//           child: CupertinoPicker(
//             itemExtent: 32,
//             onSelectedItemChanged: (int index) {
//               setState(() {
//                 _selectedHour = hours[index];
//               });
//             },
//             children: hours.map((int value) {
//               return Center(child: Text('$value'));
//             }).toList(),
//           ),
//         ),
//         // 分钟选择器
//         Container(
//           height: 200,
//           width: MediaQuery.of(context).size.width / 3,
//           child: CupertinoPicker(
//             itemExtent: 32,
//             onSelectedItemChanged: (int index) {
//               setState(() {
//                 _selectedMinute = minutes[index];
//               });
//             },
//             children: minutes.map((int value) {
//               return Center(child: Text('$value'));
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }
// }



class DateRangePickerExample extends StatefulWidget {
  @override
  _DateRangePickerExampleState createState() => _DateRangePickerExampleState();
}

class _DateRangePickerExampleState extends State<DateRangePickerExample> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedStartDate != null && pickedStartDate != _startDate) {
      setState(() {
        _startDate = pickedStartDate;
      });
    }

    final DateTime? pickedEndDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedEndDate != null && pickedEndDate != _endDate) {
      setState(() {
        _endDate = pickedEndDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('选择日期范围'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text('选择日期'),
            ),
            Text(
              _startDate == null ? '未选择' : '开始日期: ${_startDate!.toIso8601String()}',
            ),
            Text(
              _endDate == null ? '未选择' : '结束日期: ${_endDate!.toIso8601String()}',
            ),
          ],
        ),
      ),
    );
  }
}
