import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

final db = FirebaseFirestore.instance;

DateTime now = DateTime.now();
DateTime startLastWeek = DateTime.utc(now.year, now.month, now.day - 6, 0, 0, 0);
DateTime endToday = DateTime.utc(now.year, now.month, now.day + 1,0, 0, 0);

String lastWeekStartDay = startLastWeek.toString().substring(0, 19);
String endTodayDay = endToday.toString().substring(0, 19);


class ChartPage extends StatefulWidget {
  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<DateTime> dates = [];

  List<int> watchNumber = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    List<int> watchNum = [];
    dates = getDates(startLastWeek, endToday);
    print(dates);
    for (int i = 0; i < dates.length; i++){
      String date = dates[i].toIso8601String().substring(0, 10);
      int number = await getNumberForDate(date);
      watchNum.add(number);
      print("Finish for $date, watched number is $number");
    }
    setState(() {
      watchNumber = watchNum;
    });
  }

  List<DateTime> getDates(DateTime start, DateTime end){
    List<DateTime> dates = [];
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      dates.add(start.add(Duration(days: i)));
    }
    return dates;
  }

  Future<int> getNumberForDate(String date) async {
    int watch_number = 0;
    
    final report_summary_ref = db.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).collection('Report').doc(date).collection('Summary').doc(date);
    await report_summary_ref.get().then(
      (DocumentSnapshot report_sum_doc) {
        print("Successfully completed");
        if (report_sum_doc.exists) {
          final report_sum_data = report_sum_doc.data() as Map<String, dynamic>;
          watch_number = (report_sum_data['Today_watched_video_number']);
          print("watch number: $watch_number");
        } else {
          watch_number = 0;
          print("No such document");
        }
      },
      onError: (e) => print("Error getting document: $e"),
    );

    print("Return watch number: $watch_number");
    return watch_number;
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
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final date = dates[value.toInt()];
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text("${date.month}/${date.day}"),
                      );
                    },
                  ),
                  
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: watchNumber.isNotEmpty ? watchNumber.reduce((a, b) => a > b ? a : b).toDouble() + 10 : 10,
              barGroups: watchNumber.isNotEmpty ? List.generate(dates.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: watchNumber[index].toDouble(),
                      color: Colors.blue,
                    ),
                  ],
                );
              }) : [],
            ),
          ),
        )
      ),
      
    );
  }
}