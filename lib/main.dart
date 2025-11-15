import 'package:bee_care/homepage.dart';
import 'package:bee_care/loginpage.dart';
import 'package:bee_care/signup.dart';
import 'package:flutter/material.dart';
import 'package:bee_care/splashscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // TRY THIS: Tpry running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
        routes: {
    "/login": (context) =>  LoginPage(),
  },
      home: SplashScreen()
    );
  }
}
