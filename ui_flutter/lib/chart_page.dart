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
DateTime startLastWeek = DateTime.utc(now.year, now.month, now.day - 7, 0, 0, 0);
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
  List<Map<String, double>> colorRatios = [
      {
        'Red': 0.0,
        'Yellow': 0.0,
        'Green': 0.0
      }
    ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    List<int> watchNum = [];
    List<Map<String, double>> moodRatios = [];
    dates = getDates(startLastWeek, endToday);
    print(dates);
    for (int i = 0; i < dates.length; i++){
      String date = dates[i].toIso8601String().substring(0, 10);
      Map<String, dynamic> reportSumData = await getNumberForDate(date);
      int number = reportSumData['Today_watched_video_number'] ?? 0;
      watchNum.add(number);
      int betterNum = reportSumData['Better'] ?? 0;
      int worseNum = reportSumData['Worse'] ?? 0;
      int sameNum = reportSumData['Same'] ?? 0;
      print("Better: $betterNum, Worse: $worseNum, Same: $sameNum");
      double redRatio = (betterNum.toDouble() / (betterNum + worseNum + sameNum).toDouble());
      double yellowRatio = (sameNum.toDouble() / (betterNum + worseNum + sameNum).toDouble());
      double greenRatio = (worseNum.toDouble() / (betterNum + worseNum + sameNum).toDouble());
      print("Red ratio old: $redRatio, Yellow ratio old: $yellowRatio, Green ratio old: $greenRatio");
      if (redRatio.isNaN) {
        redRatio = 0;
      }
      if (yellowRatio.isNaN) {
        yellowRatio = 0;
      }
      if (greenRatio.isNaN) {
        greenRatio = 0;
      }
      print("Red ratio: $redRatio, Yellow ratio: $yellowRatio, Green ratio: $greenRatio");
      
      moodRatios.add({
        'Red': redRatio,
        'Yellow': yellowRatio,
        'Green': greenRatio,
      });
      print("Finish for $date, watched number is $number");
    }
    setState(() {
      watchNumber = watchNum;
      colorRatios = moodRatios;
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

  @override
  Widget build(BuildContext context) {
    // dates = getDates(startLastWeek, endToday);
    // print(dates);
    

    return Scaffold(
      appBar: AppBar(
        title: Text('Viewing Behaviours Report'),
      ),
      body: Center(
        child: Container(
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
                ),
                
                minY: 0,
                maxY: watchNumber.isNotEmpty ? watchNumber.reduce((a, b) => a > b ? a : b).toDouble() + 10 : 10,
                barGroups: watchNumber.isNotEmpty ? List.generate(dates.length, (index) {
                  final ratios = colorRatios[index];
                  double totalNum = watchNumber[index].toDouble();
                  // if (totalNum.isNaN) {
                  //   totalNum = 0;
                  // }
                  double redRatio = ratios["Red"] ?? 0;
                  // if (redRatio.isNaN) {
                  //   redRatio = 0;
                  // }
                  double greenRatio = ratios["Green"] ?? 0;
                  // if (greenRatio.isNaN) {
                  //   greenRatio = 0;
                  // }
                  double yellowRatio = ratios["Yellow"] ?? 0;
                  // if (yellowRatio.isNaN) {
                  //   yellowRatio = 0;
                  // }
                  print("Red ratio now: $redRatio, Yellow ratio now: $yellowRatio, Green ratio now: $greenRatio");
                  double redValue = totalNum * redRatio;
                  double greenValue = totalNum * greenRatio;
                  double yellowValue = totalNum * yellowRatio;
                  print("Total number: $totalNum, red: $redValue, yellow: $yellowValue, green: $greenValue");

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
        )
      ),
      
    );
  }
}