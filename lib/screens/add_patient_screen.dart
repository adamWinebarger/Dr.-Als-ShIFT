import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionmakerteacher/models/answerer.dart';
import 'package:questionmakerteacher/stringextension.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key, required this.currentUser});

  final DocumentReference currentUser;

  @override
  State<StatefulWidget> createState() => _AddPatientState();
}

class _AddPatientState extends State<AddPatientScreen> {

  final _formKey = GlobalKey<FormState>();
  final CollectionReference _crList = FirebaseFirestore.instance.collection("Patients");

  String _enteredLastName = "", _enteredPatientCode = "";
  bool _isChecking4PatientData = false;
  List<String> _patientList = [];
  ParentOrTeacher? _parentOrTeacher;

  Future<String?> _patientAdded2List() async {
    String? errorMessage;
    QueryDocumentSnapshot<Object?>? foundPatient;
    String? whoIsViewable;
    print("This fires");

    //So the lazy logic here is to essentially to break out codes into a parent and teacher code
    // Since I didn't want to go back and re-write a whole bunch of stuff. This is essentially going
    //to check for one or the other, or both if _parentOrTeacher is left blank.
    if (_parentOrTeacher != ParentOrTeacher.teacher) {
      //This is essentially the parent case
      await _crList.where('lastName', isEqualTo: _enteredLastName)
          .where('parentCode', isEqualTo: _enteredPatientCode).get().then(
              (value) {
            //this basically checks to see if there's any data that matches the query, then, if so,
            // follows different paths based on how much data is returned.
            if (value.docs.isEmpty) {
              errorMessage = "No patient found with these credentials";
            } else if (value.docs.length > 1) {
              errorMessage =
              "Somehow, multiple patients were returned meeting this criteria. This means something is very wrong here. Please try again later";
            } else {
              whoIsViewable = 'viewableChildren';
              foundPatient = value.docs[0];
            }
          });
    }
    print('Error message: $errorMessage');
    print('Found patient: $foundPatient');
    //Since we're exiting the parent block, it's just going to skip this entirely
    //if it found a hit here.
    if (_parentOrTeacher != ParentOrTeacher.parent && foundPatient == null) {
      //which makes this the teacher case.
      await _crList.where('lastName', isEqualTo: _enteredLastName)
          .where('teacherCode', isEqualTo: _enteredPatientCode).get().then(
              (value) {
            //this basically checks to see if there's any data that matches the query, then, if so,
            // follows different paths based on how much data is returned.
            if (value.docs.isEmpty) {
              errorMessage = "No patient found with these credentials";
            } else if (value.docs.length > 1) {
              errorMessage =
              "Somehow, multiple patients were returned meeting this criteria. This means something is very wrong here. Please try again later";
            } else {
              errorMessage = null; //since we found a hit, the error message needs to be set back to null
              whoIsViewable = 'viewableStudents';
              foundPatient = value.docs[0];
            }
          });
    }
    //there should be no instance where the error message and the found patient are both null
    //so we'll add a new patient to the array when the error message is null
    if (errorMessage == null) {
      await widget.currentUser.update({
        whoIsViewable! : FieldValue.arrayUnion([foundPatient!.id])
      });
    }
    return errorMessage;
  }

  //remember that we ripped this from patient_list_screen. If we use it much more, then
  // we may want to consider making this a public method somewhere easily accessible with any class that may need
  //it.
  //UPDATE: This has been changed dramatically.
  Future<List<String>> _getPatientList() async {
    print("Banana");
    final currentUserData = await widget.currentUser.get();
    var viewableStudents = (currentUserData['viewableStudents'] as List).map((e) => e as String).toList();
    var viewableChildren = (currentUserData['viewableChildren'] as List).map((e) => e as String).toList();
    List<String> patientList = (viewableStudents != null && viewableStudents.isNotEmpty) ? viewableStudents : [];
    if (viewableChildren != null && viewableChildren.isNotEmpty) {
      patientList += viewableChildren;
    }
    return patientList;
  }

  void _addPatientPressed() async {
    setState(() {
      _isChecking4PatientData = true;
    });

    final allInputsValid = _formKey.currentState!.validate();

    if (allInputsValid) {
      _formKey.currentState!.save();
      String? errorMessage = await _patientAdded2List();
      if (errorMessage == null) {
        //This might not be the best practice but it works for now, I guess
        setState(() {
          Navigator.pop(context);
        });
      }
    }

    setState(() {
      _isChecking4PatientData = false;
    });

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _getPatientList().then((value) {
    //   setState(() {
    //     _patientList = value;
    //   });
    // });
  }

  @override
  Widget build(context) {
    //print(_patientList);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Child"),
      ),
      body: Padding(
        padding: EdgeInsets.all(25),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: "Last Name:"),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.trim().length < 2
                        || value.trim().length > 50) {
                      return 'Input value must be between 2 and 50 characters long';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredLastName = value!;
                  },
                ),
                const SizedBox(height: 50,),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Code:"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      //This will definitely need to be built out.
                      return "Invalid Patient Code Detected";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredPatientCode = value!;
                  },
                ),
                const SizedBox(height: 25,),
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    label: Text(
                        "Which option more closely describes your relationship with the child?",
                      style: TextStyle(fontSize: 12),
                    ),

                  ),
                    items: [
                      const DropdownMenuItem(
                        child: Text(""),
                        value: null,
                      ),
                      for (final selection in ParentOrTeacher.values)
                        DropdownMenuItem(child: Text(selection.name.capitalize()), value: selection,)
                    ],
                    onChanged: (value) => _parentOrTeacher = value
                ),
                const SizedBox(height: 50,),
                ElevatedButton(
                  onPressed: _addPatientPressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 40)
                  ),
                  child: (_isChecking4PatientData) ? const SizedBox(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator(),
                  ) : const Text("Add Patient")
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}