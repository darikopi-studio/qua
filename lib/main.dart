import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

String quotesUri = "https://raw.githubusercontent.com/darikopi-studio/qua/data/quotes.json";

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFFEC4F4F)
    ));
    return MaterialApp(
      
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Daily Quote'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Quote {
  final int id;
  final String message;
  final String by;

  Quote({this.id, this.message, this.by});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'],
      message: json['message'],
      by: json['by']
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  Future<Quote> quote;
  bool _visible = false;
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    quote = fetchQuotes();
    requestPermission();
  }

  void requestPermission() async {
    Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  }


  Future<Quote> fetchQuotes() async {
    final response = await http.get(quotesUri);
    if (response.statusCode == 200) {
      setState(() {
        _visible = true;
      });
      return Quote.fromJson(json.decode(response.body));
    } else {
      throw new Exception("failed load post");
    }
  }

  GlobalKey _globalKey = new GlobalKey();
  Future<Uint8List> _capturePng() async {
    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData.buffer.asUint8List();
      Share.file('image', 'image.png', pngBytes, 'image/png');
      return pngBytes;
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible? 1.0:0.0,
          duration: Duration(milliseconds: 500),
          child: RepaintBoundary(
            key: _globalKey,
            child: Container(
              height: MediaQuery.of(context).size.width,
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: FutureBuilder<Quote>(
                  future: quote,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            DateFormat("E, d MMMM yyyy").format(DateTime.now()),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              textStyle: TextStyle(
                                color: Color.fromRGBO(0, 0, 0, 0.3)
                              )
                            )
                          ),
                          Container(
                            height: 24.0,
                          ),
                          Text(
                            snapshot.data.message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              textStyle: TextStyle(
                                height: 1.5
                              )
                            )
                          ),
                          Container(
                            height: 18.0,
                          ),
                          Text(
                            snapshot.data.by,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.raleway(
                              fontSize: 18  ,
                              fontWeight: FontWeight.w600,
                              textStyle: TextStyle(
                                color: Color.fromRGBO(0, 0, 0, 0.3)
                              )
                            )
                          ),
                        ],
                      );
                    } else {
                      return Text("");
                    }
                  },
                ),
              ),
            ),
          ),
        )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFFEC4F4F),
        label: Text(
          "Bagikan",
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.w600            
          ),
        ),
        icon: Icon(Icons.share),
        onPressed: _visible?() {
          _capturePng();
        }:null,
      ),
    );
  }
}
