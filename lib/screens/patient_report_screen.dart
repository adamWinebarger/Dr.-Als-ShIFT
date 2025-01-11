

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:questionmakerteacher/main.dart';
import 'package:questionmakerteacher/models/report.dart';
import 'package:questionmakerteacher/models/theme_data.dart';
import 'package:questionmakerteacher/stringextension.dart';
import 'package:intl/intl.dart';

import '../models/questionnaire.dart';

final Map<Answers, String> _answerMap = {
  Answers.notAtAll : "Not at all",
  Answers.sometimes : "Sometimes",
  Answers.alot : "A Lot",
  Answers.always : "Always"
};

class PatientReportScreen extends StatelessWidget {
  PatientReportScreen({super.key, required this.currentReport});

  final Report currentReport;

  // Helper function to format DateTime to MM/DD/YYYY
  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);  // e.g., 'Jan 15, 2024'
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text("Report Viewer"),),
      body: GradientContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
            child: Center(
              child: Column(
                children: [
                  RichText(text:
                  TextSpan(children:
                  [
                    //Title
                    TextSpan(
                        text: "Report by ${currentReport.firstName} ${currentReport.lastName} (${currentReport.parentOrTeacher.name.capitalize()})\n",
                        style: Theme.of(context).textTheme.titleLarge
                    ),
                    //Subtitle
                    TextSpan(
                        text: "${currentReport.timeOfDay.capitalize()} - ${_formatDate(currentReport.timestamp)}",
                        style: Theme.of(context).textTheme.titleMedium
                    )
                  ]
                  ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25,),
                  Expanded(child:
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey, width: 2),
                        borderRadius: BorderRadius.circular(10),
                        //color: Colors.white60
                      color: Theme.of(context).colorScheme.secondary
                    ),
                    child: ListView.builder(
                      itemCount: currentReport.answers.length,
                      itemBuilder: (context, index) {
                        String key = currentReport.answers.keys.elementAt(index),
                            value = _answerMap[currentReport.answers[key]]!;

                        return Container(
                          decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.blueGrey, width: 1)
                              )
                          ),
                          child: ListTile(
                            title: Text(key),
                            subtitle: Text("\t$value"),
                          ),
                        );
                      },
                    ),
                  )
                  ),
                  SizedBox(height: 35,)
                ],
              ),
            ),
          ),
      )
    );
  }


}