import 'dart:ffi';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

final db = FirebaseFirestore.instance;

DateTime now = DateTime.now();
DateTime startLastWeek = DateTime.utc(now.year, now.month, now.day - 6, 0, 0, 0);
DateTime endToday = DateTime.utc(now.year, now.month, now.day);

String lastWeekStartDay = startLastWeek.toString().substring(0, 19);
String endTodayDay = endToday.toString().substring(0, 19);


class ChartPage extends StatefulWidget {
  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<DateTime> dates = [];
  List<int> watchNumber = [];
  List<Map<String, double>> colorRatios = [];
  List<Map<String, dynamic>> dayDetails = [];
  SelectedBarInfo? _selectedBar;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    List<int> watchNum = [];
    List<Map<String, double>> moodRatios = [];
    List<Map<String, dynamic>> dayDetailsData = [];

    dates = getDates(startLastWeek, endToday);
    
    for (int i = 0; i < dates.length; i++){
      String date = dates[i].toIso8601String().substring(0, 10);
      Map<String, dynamic> reportSumData = await getNumberForDate(date);
      int number = reportSumData['Today_watched_video_number'] ?? 0;
      watchNum.add(number);
      int betterNum = reportSumData['Better'] ?? 0;
      int worseNum = reportSumData['Worse'] ?? 0;
      int sameNum = reportSumData['Same'] ?? 0;
      
      double redRatio = (betterNum.toDouble() / (betterNum + worseNum + sameNum).toDouble());
      double yellowRatio = (sameNum.toDouble() / (betterNum + worseNum + sameNum).toDouble());
      double greenRatio = (worseNum.toDouble() / (betterNum + worseNum + sameNum).toDouble());
      
      if (redRatio.isNaN) {
        redRatio = 0;
      }
      if (yellowRatio.isNaN) {
        yellowRatio = 0;
      }
      if (greenRatio.isNaN) {
        greenRatio = 0;
      }
      
      moodRatios.add({
        'Red': redRatio,
        'Yellow': yellowRatio,
        'Green': greenRatio,
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
    Map<String, dynamic> betterData = {'color': '#FF0000'};
    Map<String, dynamic> sameData = {'color': '#FFFF00'};
    Map<String, dynamic> worseData = {'color': '#008000'};

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
    // dates = getDates(startLastWeek, endToday);
    // print(dates);
    

    return Scaffold(
      appBar: AppBar(
        title: Text('Viewing Behaviours Report'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(16.0),
              width: MediaQuery.of(context).size.width * 0.9,
              height: 300,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10.0),
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: false),
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
                            final xValue = dates[touchedIndex].toString();
                            _selectedBar = SelectedBarInfo(
                              touchResponse!.spot!.touchedBarGroupIndex,
                              touchResponse.spot!.touchedRodData.toY,
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
                      double redRatio = ratios["Red"] ?? 0;
                      double greenRatio = ratios["Green"] ?? 0;
                      double yellowRatio = ratios["Yellow"] ?? 0;
                      
                      double redValue = totalNum * redRatio;
                      double greenValue = totalNum * greenRatio;
                      double yellowValue = totalNum * yellowRatio;
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: totalNum,
                            rodStackItems: [
                              BarChartRodStackItem(0, redValue, Colors.red),
                              BarChartRodStackItem(redValue, redValue + yellowValue, Colors.yellow),
                              BarChartRodStackItem(redValue + yellowValue, totalNum, Colors.green),
                            ]
                          ),
                        ],
                      );
                    }) : [],
                  ),
                  
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
          title: Text('Details'),
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
          'Group: ${_selectedBar!.groupIndex}, Value: ${_selectedBar!.rodValue}',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 10),
        ...selectedDayDetails.entries.expand((entry) {
          Color color = getColor(entry.key);
          Map<String, dynamic> statusData = entry.value;
          List<Widget> widgets = [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(width: 20, height: 20, color: getColor(entry.key)), // 使用 getColor 函数获取颜色
                  // SizedBox(width: 10),
                  // Text(entry.key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ...statusData.entries.where((dataEntry) => dataEntry.key != 'color').map((dataEntry) { // 排除 color 键
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

  // Color getColor(String colorStr) {
  //   String colorValue = '0xFF' + colorStr.substring(1);
  //   Color color = Color(int.parse(colorValue, radix: 16));
  //   return color;
  // }
  Color getColor(String status) {
    switch (status) {
      case 'better':
        return Colors.red;
      case 'same':
        return Colors.yellow;
      case 'worse':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }



}

class SelectedBarInfo {
  final int groupIndex;
  final double rodValue;
  final String xValue;

  SelectedBarInfo(this.groupIndex, this.rodValue, this.xValue);
}
