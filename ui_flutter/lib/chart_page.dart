import 'dart:ui';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'report_page.dart';

final db = FirebaseFirestore.instance;

// DateTime now = DateTime.now();
// DateTime startLastWeek = DateTime.utc(now.year, now.month, now.day - 6, 0, 0, 0);
// DateTime endToday = DateTime.utc(now.year, now.month, now.day);

// String lastWeekStartDay = startLastWeek.toString().substring(0, 19);
// String endTodayDay = endToday.toString().substring(0, 19);


class ChartPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  ChartPage({required this.startDate, required this.endDate});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _startDateStr = '';
  String _endDateStr = '';

  List<DateTime> dates = [];
  List<int> watchNumber = [];
  List<Map<String, double>> colorRatios = [];
  List<Map<String, dynamic>> dayDetails = [];
  SelectedBarInfo? _selectedBar;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _startDateStr = _startDate.toString().substring(0, 19);
    _endDateStr = _endDate.toString().substring(0, 19);
    _fetchData(_startDate, _endDate);
  }

  void _fetchData(DateTime startDate, DateTime endDate) async {
    List<int> watchNum = [];
    List<Map<String, double>> moodRatios = [];
    List<Map<String, dynamic>> dayDetailsData = [];

    dates = getDates(startDate, endDate);
    
    for (int i = 0; i < dates.length; i++){
      String date = dates[i].toIso8601String().substring(0, 10);
      Map<String, dynamic> reportSumData = await getNumberForDate(date);
      int number = reportSumData['Today_watched_video_number'] ?? 0;
      watchNum.add(number);
      int betterNum = reportSumData['Better'] ?? 0;
      int worseNum = reportSumData['Worse'] ?? 0;
      int sameNum = reportSumData['Same'] ?? 0;
      
      double greenRatio = (betterNum.toDouble() / (betterNum + worseNum + sameNum).toDouble());
      double yellowRatio = (sameNum.toDouble() / (betterNum + worseNum + sameNum).toDouble());
      double redRatio = (worseNum.toDouble() / (betterNum + worseNum + sameNum).toDouble());
      
      if (greenRatio.isNaN) {
        greenRatio = 0;
      }
      if (yellowRatio.isNaN) {
        yellowRatio = 0;
      }
      if (redRatio.isNaN) {
        redRatio = 0;
      }
      moodRatios.add({
        'Green': greenRatio,
        'Yellow': yellowRatio,
        'Red': redRatio,
      });
      print("Finish for $date, watched number is $number");

      Map<String, dynamic> detailsData = await getDetailsForDate(date);
      dayDetailsData.add(detailsData);
      // print(dayDetailsData);
    }
    setState(() {
      watchNumber = watchNum;
      colorRatios = moodRatios;
      dayDetails = dayDetailsData;
    });
  }

  List<DateTime> getDates(DateTime start, DateTime end){
    List<DateTime> dates = [];
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      dates.add(start.add(Duration(days: i)));
    }
    return dates;
  }

  Future<Map<String, dynamic>> getNumberForDate(String date) async {
    Map<String, dynamic> reportSummaryData = {};
    
    final reportSummaryRef = db.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).collection('Report').doc(date).collection('Summary').doc(date);
    await reportSummaryRef.get().then(
      (DocumentSnapshot reportSumDoc) {
        if (reportSumDoc.exists) {
          reportSummaryData = reportSumDoc.data() as Map<String, dynamic>;
        } else {
          print("No such document");
        }
      },
      onError: (e) => print("Error getting document: $e"),
    );
    return reportSummaryData;
  }

  Future<Map<String, dynamic>> getDetailsForDate(String date) async {
    Map<String, dynamic> betterData = {};
    Map<String, dynamic> sameData = {};
    Map<String, dynamic> worseData = {};

    final reportDetailsRef = db.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).collection('Report').doc(date).collection('Details');
    await reportDetailsRef.get().then(
      (querySnapshot) {
      for (var detailsDoc in querySnapshot.docs) {
        if (detailsDoc.exists) {
          print('file exists');
          Map<String, dynamic> docData = detailsDoc.data() as Map<String, dynamic>;
          String status = docData['Mood Status'];
          print(status);
          Map<String, dynamic> targetMap;

          switch (status) {
            case 'Better':
              targetMap = betterData;
              break;
            case 'Same':
              targetMap = sameData;
              break;
            case 'Worse':
              targetMap = worseData;
              break;
            default:
              continue;
          }

          docData.forEach((key, value) {
            if (key != 'Mood Status' && key != 'Start Watching Time' && key != 'Stop Watching Time' && key != 'Total watched video number') { 
              if (targetMap.containsKey(key)) {
                targetMap[key] += value; // 累加值
              } else {
                targetMap[key] = value; // 新字段初始化
              }
            }
          });
          // print(targetMap);
        } else {
          print("No such document");
        }
      };
    });

    // 汇总数据
    Map<String, dynamic> detailsDataCollection = {
      'better': betterData,
      'same': sameData,
      'worse': worseData,
    };

    return detailsDataCollection;
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double minBarWidth = 50; // 每个数据点的最小宽度
    double chartWidth = dates.length * minBarWidth;
    int maxYNum = watchNumber.isNotEmpty ? watchNumber.reduce((a, b) => a > b ? a : b).toInt() + 10 : 10;

    return Scaffold(
      appBar: AppBar(
        title: Text('Viewing Report', style: TextStyle(color: Color.fromRGBO(72, 61, 139, 1))),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false, // 设置为透明的
                    barrierDismissible: true, // 点击背景时是否可以关闭页面
                    pageBuilder: (context, _, __) {
                      DateTime now = DateTime.now();

                      return Opacity(
                        opacity: 0.8,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(230, 230, 250, 1),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(25),
                                bottomRight: Radius.circular(25),
                              ),
                              // backgroundBlendMode: BlendMode.dstOver,
                              
                            ),
                            child: Center(
                              // child: Text('这是从顶部弹出的页面'),
                              child: SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 50.0),
                                  child: Column(
                                    children: <Widget>[
                                      Text('Edit Time Range',
                                       style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                        color: Color.fromRGBO(72, 61, 139, 1))),
                                      SizedBox(height: 30),
                                      // 创建三个并排的按钮
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          ElevatedButton(
                                            onPressed: () {
                                              // 近1月按钮的功能
                                              setState(() {
                                                _startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 29));
                                                _startDateStr = _startDate.toString().substring(0, 19);
                                                _endDate = DateTime(now.year, now.month, now.day);
                                                _endDateStr = _endDate.toString().substring(0, 19);
                                              });
                                            },
                                            child: Text(
                                              'Last Month', 
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromRGBO(106, 90, 205, 0.4),
                                              foregroundColor: Colors.brown[900],
                                              alignment: Alignment.center,
                                              maximumSize: Size(screenWidth * 0.28, 60),
                                              splashFactory: NoSplash.splashFactory,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              // 近3月按钮的功能
                                              setState(() {
                                                _startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 89));
                                                _startDateStr = _startDate.toString().substring(0, 19);
                                                _endDate = DateTime(now.year, now.month, now.day);
                                                _endDateStr = _endDate.toString().substring(0, 19);
                                              });
                                            },
                                            child: Text('Last 3 Months', style: TextStyle(fontSize: 11)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromRGBO(106, 90, 205, 0.4),
                                              foregroundColor: Colors.brown[900],
                                              alignment: Alignment.center,
                                              maximumSize: Size(screenWidth * 0.31, 60),
                                              splashFactory: NoSplash.splashFactory,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              // 近6月按钮的功能
                                              setState(() {
                                                _startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 179));
                                                _startDateStr = _startDate.toString().substring(0, 19);
                                                _endDate = DateTime(now.year, now.month, now.day);
                                                _endDateStr = _endDate.toString().substring(0, 19);
                                              });
                                            },
                                            child: Text('Last Half Year', style: TextStyle(fontSize: 11)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromRGBO(106, 90, 205, 0.4),
                                              foregroundColor: Colors.brown[900],
                                              alignment: Alignment.center,
                                              maximumSize: Size(screenWidth * 0.31, 60),
                                              splashFactory: NoSplash.splashFactory,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              side: BorderSide(
                                                style: BorderStyle.none,
                                              )
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 30), // 添加一些垂直间隔
                                      // 创建一行显示两个可点击的日期按钮
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              // 开始日期按钮点击事件，弹出日期选择器
                                              _selectDate(context, true); // 假设这是开始日期按钮
                                            },
                                            child: Text(_startDate.toString().substring(0, 10)), // 开始日期变量，格式化为你需要的样式
                                          ),
                                          const Text(
                                            '—',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                              decoration: TextDecoration.none),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              // 结束日期按钮点击事件，弹出日期选择器
                                              _selectDate(context, false); // 假设这是结束日期按钮
                                            },
                                            child: Text(_endDate.toString().substring(0, 10)),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () async {
                                          // 确定按钮的功能
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          await handleData(true, FirebaseAuth.instance.currentUser!.uid, _startDateStr, _endDateStr);
                                          _fetchData(_startDate, _endDate);
                                          setState(() {
                                            _isLoading = false;
                                          });
                                          Navigator.of(context).pop(); // 关闭弹出页面
                                        },
                                        child: Text('Confirm'),
                                      ),
                                      // if (_isLoading)
                                      //   Center(
                                      //     child: SpinKitCircle(
                                      //       color: Colors.blue,
                                      //       duration: Duration(seconds: 3),
                                      //       size: 100.0,
                                      //     ),
                                      //   ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              child: Text('Filter'),
            ),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      width: chartWidth > screenWidth ? chartWidth : screenWidth,
                      height: 300,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final date = dates[value.toInt()];
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text("${date.month}/${date.day}"),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                )
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                )
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                // getTooltipColor: Colors.transparent,
                                tooltipPadding: const EdgeInsets.all(0),
                                tooltipMargin: 8,
                                getTooltipItem: (
                                  BarChartGroupData group,
                                  int groupIndex,
                                  BarChartRodData rod,
                                  int rodIndex,
                                ) {
                                  return BarTooltipItem(
                                    rod.toY.round().toString(),
                                    const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
                                if (event is! FlTapUpEvent && event is! FlLongPressEnd) {
                                  return;
                                }
                                setState(() {
                                  if (touchResponse?.spot != null) {
                                    final touchedIndex = touchResponse!.spot!.touchedBarGroupIndex;
                                    final date = dates[touchedIndex];
                                    final xValue = '${date.month}/${date.day}';
                                    _selectedBar = SelectedBarInfo(
                                      touchResponse.spot!.touchedBarGroupIndex,
                                      touchResponse.spot!.touchedRodData.toY.toInt(),
                                      xValue,
                                    );
                                    showDetailsDialog(context);
                                  } else {
                                    _selectedBar = null;
                                  }
                                });
                              },
                            ),
                            minY: 0,
                            maxY: watchNumber.isNotEmpty ? watchNumber.reduce((a, b) => a > b ? a : b).toDouble() + 10 : 10,
                            barGroups: watchNumber.isNotEmpty ? List.generate(dates.length, (index) {
                              final ratios = colorRatios[index];
                              double totalNum = watchNumber[index].toDouble();
                              double greenRatio = ratios["Green"] ?? 0;
                              double yellowRatio = ratios["Yellow"] ?? 0;
                              double redRatio = ratios["Red"] ?? 0;
                              
                              double greenValue = totalNum * greenRatio;
                              double yellowValue = totalNum * yellowRatio;
                              double redValue = totalNum * redRatio;

                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    fromY: 0,
                                    toY: totalNum,
                                    width: 10,
                                    rodStackItems: [
                                      BarChartRodStackItem(0, greenValue, Colors.green),
                                      BarChartRodStackItem(greenValue, greenValue + yellowValue, Colors.yellow),
                                      BarChartRodStackItem(greenValue+ yellowValue, totalNum, Colors.red),
                                    ]
                                  ),
                                ],
                              );
                            }) : [],
                          ),
                          
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.only(left: 80, top: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          color: Colors.green,
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Videos Make You Feel Better'),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          color: Colors.yellow,
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Videos don\'t change your Feeling'),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          color: Colors.red,
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Videos Make You Fell Worse'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      ),
      
    );
  }

  void showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView( // 如果内容很多，需要滚动
            child: _buildDetailsView(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Widget _buildDetailsView() {
    if (_selectedBar == null) return SizedBox.shrink(); // 没有选中的柱子时不显示

    Map<String, dynamic> selectedDayDetails = dayDetails[_selectedBar!.groupIndex];

    // 根据 _selectedBar 的信息显示详细信息
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Date: ${_selectedBar!.xValue}, Total Numbers: ${_selectedBar!.rodValue}',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 10),
        ...selectedDayDetails.entries.expand((entry) {
          Color color = getColor(entry.key);
          Map<String, dynamic> statusData = entry.value;
          List<Widget> widgets = [
            ...statusData.entries.map((dataEntry) {
              return Padding(
                padding: const EdgeInsets.only(left: 30.0), // 左边距为对齐
                child: Row(
                  children: [
                    Container(width: 10, height: 10, color: color),
                    SizedBox(width: 10),
                    Text('${dataEntry.key}: ${dataEntry.value}')],
                )
                
              );
            }).toList()
          ];
          return widgets;
        
        }).toList(),
          
        
      ],
    );
  }

  Color getColor(String status) {
    switch (status) {
      case 'better':
        return Colors.green;
      case 'same':
        return Colors.yellow;
      case 'worse':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate, // 根据是开始日期还是结束日期来决定
      firstDate: DateTime(2000), // 可选择的最早日期
      lastDate: DateTime.now(), // 可选择的最晚日期
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked; // 更新开始日期变量
          _startDateStr = _startDate.toString().substring(0, 19);
        } else {
          _endDate = picked; // 更新结束日期变量
          _endDateStr = _endDate.toString().substring(0, 19);
        }
      });
      // 如果需要，可以在这里将日期传输到别的地方
    }
  }
  
  Future<void> handleData(bool handleData, String userUid, String startDate, String endDate) async {
    print('666');
    final url = Uri.parse('https://sms-app-project-415923.nw.r.appspot.com/api/handle_data');
    // final url = Uri.parse('http://localhost:5000/api/handle_data');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "handle_data": handleData,
        "userUid": userUid,
        "startDate": startDate,
        "endDate": endDate,
      }),
    );
    print('999');
    print(response.statusCode);
    if (response.statusCode == 200) {
      print('Response from server: ${response.body}');
    } else {
      print('Failed to send command.');
    }
  }
}

class SelectedBarInfo {
  final int groupIndex;
  final int rodValue;
  final String xValue;

  SelectedBarInfo(this.groupIndex, this.rodValue, this.xValue);
}
