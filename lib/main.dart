import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:questionmakerteacher/models/theme_data.dart';
import 'package:questionmakerteacher/screens/auth.dart';
import 'package:questionmakerteacher/screens/patient_list_screen.dart';
import 'package:questionmakerteacher/screens/splash.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dr. Al\'s SHIFT',
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF92b662),
            primary: Color(0xFF92b662),
          secondary: Color(0xFF484747),
          //brightness: Brightness.light,
          surface: Color(0xFF92b662),
        ),
        iconTheme: IconThemeData(
          //color: Color(0xfffffcfc)
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (states) {
                  return TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 14
                  );
                }
            ),

            // backgroundColor: WidgetStatePropertyAll<Color>(
            //     Colors.white
            // )
          )
        ),

        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(Colors.white)
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
            color: Colors.white
          )
        ),
        textTheme: TextTheme(
          titleMedium: TextStyle(
            //backgroundColor: Colors.black,
            //backgroundColor: Color(0xff388e3c)
            //color: Colors.white
           color: Colors.black,
          ),
          titleLarge: TextStyle(
            color: Colors.black,

          ),
          bodyMedium: TextStyle(
            color: Theme.of(context).colorScheme.secondary
          )
        ),
        //scaffoldBackgroundColor: Color(0xFF92b662)//const Color(0xff8f8f8f),
        // dropdownMenuTheme: DropdownMenuThemeData(
        //   menuStyle: MenuStyle(
        //     backgroundColor: WidgetStateProperty.all(Color(0xFF484747)),
        //
        //   )
        // )
        listTileTheme: ListTileThemeData(
          textColor: Colors.white
        )
      ),

      // darkTheme: ThemeData.dark().copyWith(
      //     useMaterial3: true,
      //     colorScheme: ColorScheme.fromSeed(
      //         seedColor: Colors.deepPurple.shade400,
      //         brightness: Brightness.dark,
      //         surface: const Color.fromARGB(255, 42, 51, 59),
      //
      //     ),
      //     scaffoldBackgroundColor: const Color.fromARGB(255, 50, 58, 60)
      // ),
      home: Scaffold(
        // appBar: AppBar(
        //   title: const Center(child: Text("Theme tests"),),
        // ),
        body: GradientContainer(
          child: StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, dataSnapshot) {
                if (dataSnapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }

                if (dataSnapshot.hasData) {
                  /* Okay, so it looks like since we're listening for changes to
              * datasnapshot up here so there's no real reason to do the admin check
              * down at auth. Instead, we need to do the check up here, for a doc
              * with the current user UID, check within to see if there's an adminID,
              * and then prompt the user up here... I guess*/

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(dataSnapshot.data!.uid).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const SplashScreen();
                      }

                      if (userSnapshot.hasData) {
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

                        //check if adminID exists within this doc
                        if (userData != null && userData.containsKey('adminID')) {

                          return PatientListScreen(isAdmin: true);
                        }

                        //case for when we don't find an adminID
                        return PatientListScreen(isAdmin: false);
                      } else {
                        return const AuthScreen();
                      }
                    },
                  );
                  //return const PatientListScreen(isAdmin: false,);
                } else {
                  return const AuthScreen();
                }
              }
          ),
        )
      )
    );
  }

  FutureBuilder<void> _showAdminDialog(BuildContext context, DocumentSnapshot userDoc) {
    return FutureBuilder<void>(
      future: showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Admin Account Found"),
            content: const Text("It appears there is a therapist/administrative account associated with this email. "
                "Would you like to log in to your admin account?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Yes")
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("No")
              )
            ],
          );
        }
      ).then((isAdmin) {
        if (isAdmin == true) {
          //Pushing to PatientScreen in Admin Mode
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PatientListScreen(isAdmin: true))
          );
        } else {
          //Regular PatientListScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PatientListScreen(isAdmin: false))
          );
        }
      }),
      builder: (context, snapshot) {
        return const SplashScreen();
      },
    );
  }
}