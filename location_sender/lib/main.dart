import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';


String number = "unknown";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Sender',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Location Sender'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _position = "Lat: Unknown, Long: Unknown";
  List<String> _addresses = ["[placeholder]"];
  String _addressesString = "Your location and phone number needs to be updated. Please click "
      "the \"Get location and phone number\" button until the information is updated to start sending messages.";
  static const platform = const MethodChannel('send_SMS');
  String _result = "[placeholder]";
  int updateTime = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool sendMessage = true;

  Future<void> _sendSMS(String message) async {
    String result;
    getPhoneNumber();
    try {
      await platform.invokeMethod('sendSMS', <String, String>{
        'number': number,
        'message': message,
      });
      result = "SMS sent successfully to " + number + ".";
    } on PlatformException catch (e) {
      result = "Failed to send SMS: '${e.message}'.";
    }

    setState(() {
      _result = result;
    });
    print("message sent");
  }

  Future<void> getLocation() async {
    getPhoneNumber();
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    _position = position.toString();

    List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);

    for(int i = 0; i < placemark.length; i++) {
      _addresses.add(placemarkToString(placemark[i]));
    }

    if(_addresses.length == 1) {
      _addressesString = _addresses[0];
    }
    else {
      for(int i = 0; i < _addresses.length; i++) {
        if(i != (_addresses.length - 1)) {
          _addressesString += (_addresses[i] + " OR ");
        }
        else {
          _addressesString += _addresses[i];
        }
      }
    }
  }

  String placemarkToString(Placemark placemark) {
    return placemark.name + " " + placemark.thoroughfare + ", " +
        placemark.locality + ", " + placemark.administrativeArea + " " +
        placemark.postalCode + ", " + placemark.country;
  }

  getPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    number = prefs.getString('number');
  }

  _displaySnackBar(BuildContext context, String string) {
    final snackBar = SnackBar(content: Text(string));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  _outputLocation() {
    setState(() {
      _addresses = [];
      getLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
                icon: Icon(IconData(59576, fontFamily: 'MaterialIcons')),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecondRoute()),
                ),
            )
            ]
        ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              '\n\n\n\nYour current location is:\n',
            ),
            Text(
              _addressesString,
              style: Theme.of(context).textTheme.headline,
              textAlign: TextAlign.center,
            ),
            Text(
              "\n" + _position + "\n\n\n",
              style: Theme.of(context).textTheme.headline,
            ),
            Text(
              number,
              style: Theme.of(context).textTheme.headline,
            ),
            FlatButton(
                color: Colors.blue,
                onPressed: () {
                  setState(() {
                    sendMessage = !sendMessage;
                  });
                  print("stopped");
                },
                child: const Text(
                    "Pause/Resume Sending Messages",
                    style: TextStyle(color: Colors.white)
                )
            ),
          ],
        ),
      ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
                child: new SizedBox(
                  width: 30,
                  height: 1,
                ),
            ),
            Material(
                child: new SizedBox(
                    child: new FlatButton(
                        color: Colors.blue,
                        onPressed: _outputLocation,
                        child: const Text(
                            "Get location and\n "
                                "phone number",
                            style: TextStyle(color: Colors.white)
                        )
                    ),
                  width: 135.0,
                  height: 60.0,
                ),
            ),
            Material(
              child: new SizedBox(
                width: 40,
                height: 1,
              ),
            ),
            Material(
                child: new SizedBox(
                    child: new FlatButton(
                        color: Colors.blue,
                        onPressed: () {
                          Timer t;
                          int count = 0;

                          const oneSec = const Duration(seconds: 5);

                          new Timer.periodic(oneSec, (t) {

                            _sendSMS("Current approximate location(s): " +
                                _addressesString);
                            _displaySnackBar(context, _result);

                            count++;

                            if(count >= 10) {
                              t.cancel();
                              print("bye");
                          }});
                        },
                        child: Text(
                            "Send SMS to \n" + number,
                            style: TextStyle(color: Colors.white)
                        )
                    ),
                  width: 135.0,
                  height: 60.0,
                ),
            ),
          ]
        ),
    );
  }
}

class SecondRoute extends StatelessWidget {

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  _saveNumber(String phonenumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('Phone number is $phonenumber.');
    await prefs.setString('number', phonenumber);
    number = phonenumber;
  }

  _displaySnackBar(BuildContext context) {
    final snackBar = SnackBar(content: Text('Data saved!'));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Material(
        child: Column(
          children: [
              Text(
                  "\nUpdate Phone Number\n",
                  style: Theme.of(context).textTheme.headline
              ),
              Text(
                  "New phone number:\n"
              ),
              Material(
                child:  Form(
                  key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          autofocus: true,
                          decoration: InputDecoration(
                              border: OutlineInputBorder()
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter some text';
                            } else if ((value.length != 10) || (int.parse(value)
                                .toString().length != 10)) {
                              return 'Please enter a valid US phone number';
                            }
                            _saveNumber(value);
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 50.0
                          ),
                          child: RaisedButton(
                            onPressed: () {
                              if (_formKey.currentState.validate()) {
                                _displaySnackBar(context);

                              }
                            },
                            child: Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ),
              )
          ]
        )
      ),
    );
  }
}
