import 'dart:ffi';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

main(List<String> args) {
  runApp(Home());
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeSttful());
  }
}

class HomeSttful extends StatefulWidget {
  @override
  _HomeSttfulState createState() => _HomeSttfulState();
}

VideoPlayerController cn;
bool viex = false;

FirebaseMessaging fcm = FirebaseMessaging();
String token;
final db = FirebaseDatabase.instance.reference();
AndroidDeviceInfo androidDeviceInfo;
String mediaUrl, mediaSrc;
bool newData = false;

class _HomeSttfulState extends State<HomeSttful> {
  void initializingdb() async {
    await Firebase.initializeApp();
    print("token is ");
    fcm.getToken().then((value) => token = value);
    DeviceInfoPlugin dev = DeviceInfoPlugin();
    androidDeviceInfo = await dev.androidInfo;
    print(androidDeviceInfo.model);
  }

  void addRealdb() async {
    var pos = await getLocation();

    String id = db.child('devices').push().key;
    db.child('devices').child(id).set({
      'id': id,
      'lan': pos['lan'],
      'lon': pos['lon'],
      'token': token,
      'devicemodel': androidDeviceInfo.model
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    initializingdb();

    super.initState();

    fcm.configure(onMessage: (Map<String, dynamic> message) async {
      print("onMessage: $message ");
      addRealdb();
      setState(() {
        //newData = true;
        mediaUrl = message['notification']['body'];
        mediaSrc = message['notification']['title'];
        newData = true;
      });
    }, onLaunch: (Map<String, dynamic> message) async {
      print("onLaunch: $message");
    }, onResume: (Map<String, dynamic> message) async {
      print("onResume: $message");
    });
  }
  //dYIKd0JuRma_xw30vBVlH5:APA91bG7e0ZH0ua69N18LN2tGK7bNIfM-0snfzGOJdOWs0JMcCEcXZnyVZ-UPf49_JSsn-TRfgXc9o1dpMtCXkHf_QMkZtwny7YxINFUL2h10HTSD3Wm163G1-rEUf-Z5gIWbkUJ6USz

  Future getLocation() async {
    Position pos = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    var data = {'lan': pos.latitude, 'lon': pos.longitude};
    return data;
  }

  cloudReciever(String src, String url) {
    print("the src : $src ");
    print("the url : $url");
    switch (src) {
      case 'image':
        return homescreenImage(url);
        break;
      case 'video':
        return homescreenVideo(url);
        break;
      case 'web':
        return homescreenWeb(url);
        break;
      case 'audio':
        return homescreenAudio(url);
        break;
      default:
        return Text('no data found');
    }
  }

  homescreenImage(String url) {
    print(url);
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Image.network(
        url,
        fit: BoxFit.fill,
      ),
    );
  }

  initVideo(String vidUrl) {
    cn = VideoPlayerController.network(vidUrl)
      ..initialize().then((value) {
        setState(() {
          print('ready initialized');
        });
        cn.setLooping(true);
        cn.play();
      });
  }

  homescreenVideo(String url) {
    if (!viex) {
      initVideo(url);
      setState(() {
        viex = true;
      });
    }

    return Flexible(
      child: cn.value.initialized
          ? AspectRatio(
              aspectRatio: cn.value.aspectRatio,
              child: VideoPlayer(cn),
            )
          : CircularProgressIndicator(),
    );
  }

  homescreenWeb(String url) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: WebView(
        initialUrl: url,
      ),
    );
  }

  IconData icon = Icons.pause;
  final assetsAudioPlayer = AssetsAudioPlayer();

  homescreenAudio(String url) {
    assetsAudioPlayer.open(
      Audio.network(
          "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
    );
    return IconButton(
        icon: Icon(icon),
        onPressed: () {
          if (assetsAudioPlayer.isPlaying.value) {
            assetsAudioPlayer?.dispose();
            setState(() {
              icon = Icons.play_arrow;
            });
          } else {
            assetsAudioPlayer?.play();
            setState(() {
              icon = Icons.pause;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);

    return Scaffold(
      body: Center(
          child: Column(
        children: <Widget>[
          if (!newData)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  FlatButton(
                      onPressed: () {
                        print(mediaUrl);
                        setState(() {
                          newData = false;
                        });
                      },
                      child: Text('add more')),
                ],
              ),
            ),
          if (newData) cloudReciever(mediaSrc, mediaUrl),
        ],
      )),
    );
  }
}
