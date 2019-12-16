import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

// Constanta
String quotesUri = "https://raw.githubusercontent.com/darikopi-studio/qua/data/quotes.json";

SharedPreferences prefs;

// In memory data
List<Quote> quotes;
int index = -1;
int lastFetch = -1;
int lastRandom = -1;

Quote noInternet = Quote(
  message: 'Sabar menanti, internetmu mati.',
  by: '@darikopi.studio',
  byLink: 'https://instagram.com/darikopi.studio'
);

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
  final String id;
  final String message;
  final String by;
  final String byLink;

  Quote({this.id, this.message, this.by, this.byLink});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'],
      message: json['message'],
      by: json['by'],
      byLink: json['by_link']
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  
  bool _visible = false;
  String _platformVersion = 'Unknown';
  Quote quote;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() async {
    // Setup cache
    await _setupPrefs();

    var now = DateTime.now().millisecondsSinceEpoch;

    // Fetch data
    if (now - lastFetch > 1 * 24 * 60 * 60 * 1000) {
      await _fetchQuotes();
    }

    await _fetchFromCache();

    // Random data
    if (now - lastRandom > 5 * 60 * 1000 && quotes.length > 0) {
      await _randomData();
    }

    if (index > -1) {
      setState(() {
        quote = quotes[index];
        _visible = true;
      });
    }
  }

  _setupPrefs() async {
    prefs = await SharedPreferences.getInstance();
    lastFetch = await prefs.getInt('lastFetch')??-1;
    lastRandom = await prefs.getInt('lastRandom')??-1;
    index = await prefs.getInt('quoteIndex')??-1;
  }
  
  _fetchQuotes() async {
    final response = await http.get(quotesUri);
    if (response.statusCode == 200) {
      
      var now = DateTime.now().millisecondsSinceEpoch;
      // save to shared preferences
      await prefs.setString('quotes', response.body);
      await prefs.setInt('lastFetch', now);
      lastFetch = now;
      
    } else {
      throw new Exception("failed load post");
    }
  }

  _fetchFromCache() async {
    var quotesData = await prefs.getString('quotes') ?? '';
    if (quotesData == '') {
      // Set last fetch to -1
      await prefs.setInt('lastFetch', -1);
    } else {
      var _quotes = List<Quote>();
      List<dynamic> quoteResponse = json.decode(quotesData);
      quoteResponse.forEach((q) {
        _quotes.add(Quote.fromJson(q));
      });
      quotes = _quotes;
    }
  }

  _randomData() async {
    var now = DateTime.now().millisecondsSinceEpoch;

    var rand = Random().nextInt(quotes.length);

    await prefs.setInt('lastRandom', now);
    await prefs.setInt('quoteIndex', rand);

    lastFetch = now;
    index = rand;
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
      Share.file('Bagikan quote', 'quote.png', pngBytes, 'image/png');
      return pngBytes;
    } catch (e) {
      print(e);
    }
  }

  _launchURL(String link) async {
  if (await canLaunch(link)) {
    await launch(link);
  } else {
    throw 'Could not launch $link';
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
                child: _visible?Column(
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
                      quote.message,
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
                    GestureDetector(
                      child: Text(
                        quote.by,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 18  ,
                          fontWeight: FontWeight.w600,
                          textStyle: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 0.3)
                          )
                        )
                      ),
                      onTap: (){
                        _launchURL(quote.byLink);
                      },
                    ),
                  ],
                ):null,
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
