import 'package:flutter/material.dart';

import 'package:untitled/utils/color_utils.dart'; // Import if you have hex color utility

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("FF0000"), // Red
              hexStringToColor("FFFFFF"), // White
              hexStringToColor("808080"), // Grey
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),


        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                top: 60.0,
                left: 20.0,
                right: 20.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontFamily: 'GeneralSans',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: const <Widget>[
                    SizedBox(height: 30),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
