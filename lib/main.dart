import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:swipedetector/swipedetector.dart';
import 'dart:convert';

import 'API.dart';
import 'YoutubeIDs.dart';
import 'videoPlayer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.blueAccent,
    ),
  );
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(YoutubePlayerDemoApp());
}

/// Creates [YoutubePlayerDemoApp] widget.
class YoutubePlayerDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Youtube Player Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          color: Colors.blueAccent,
          textTheme: TextTheme(
            title: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontSize: 20.0,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.blueAccent,
        ),
      ),
      home: MyHomePage(),
    );
  }
}

/// Homepage
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  YoutubePlayerController _controller;
  TextEditingController _idController;
  TextEditingController _seekToController;

  PlayerState _playerState;
  YoutubeMetaData _videoMetaData;
  bool _isPlayerReady = false;
  double _ratio = 16 / 9;
  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  List<String> _initList = [
    'yM14PNqGy8A',
    'mA30W2dHQIo',
    'HSsqzzuGTPo',
    '54xXb7R33rQ',
    'Ky9xa_s297Y',
    'jEnd8JIMii4',
    '2GntEbGL_v0',
    'onOEns_MnC4',
    'A2_yg19Pu7Y-w',
  ];

  dynamic videoIDs = new List<YoutubeIDs>();
  _getUsers() {
    API.getUsers().then((response) {
      setState(() {
        Iterable list = json.decode(response.body);
        videoIDs = list.map((model) => YoutubeIDs.fromJson(model)).toList();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _getUsers();
    _controller = YoutubePlayerController(
      initialVideoId: _initList.first,
      flags: YoutubePlayerFlags(
        controlsVisibleAtStart: true,
        hideControls: false,
        mute: false,
        autoPlay: false,
        hideThumbnail: false,
        disableDragSeek: true,
        loop: false,
        isLive: false,
        forceHideAnnotation: false,
        forceHD: true,
        enableCaption: false,
      ),
    )..addListener(listener);
    _idController = TextEditingController();
    _seekToController = TextEditingController();
    _videoMetaData = YoutubeMetaData();
    _playerState = PlayerState.unknown;
  }

  void onReady() {
    _controller.seekTo(new Duration(minutes: 1));
    _isPlayerReady = true;
  }

  void onReadyLandscape() {
    _controller.seekTo(new Duration(minutes: 1));
    _controller.toggleFullScreenMode();
    _isPlayerReady = true;
  }

  void listener() {
    _videoMetaData = _controller.metadata;
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        _playerState = _controller.value.playerState;
      });
    }
    if (_isPlayerReady) {
      _playerState = _controller.value.playerState;
      print(_playerState);
    }

    if (_controller.value.playerState == PlayerState.paused) {
      print('Paused');
    }

    var screenSize = MediaQuery.of(context).size;
    var size;
    Orientation currentOrientation = MediaQuery.of(context).orientation;
    if (currentOrientation == Orientation.portrait) {
      // 1.777 is 4K video ratio ( 16/9 )
      size = Size(screenSize.height * 1.777, screenSize.height);
      _controller.fitHeight(size);
    } else {
      // (screen.width/ screen.height)/1.777 = 1.125 is device height / video height ( 16 )
      size = Size(screenSize.width,
          screenSize.height * ((screenSize.width / screenSize.height) / 1.777));
      _controller.fitHeight(size);
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _idController.dispose();
    _seekToController.dispose();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        String wifiName, wifiBSSID, wifiIP;

        try {
          if (Platform.isIOS) {
            LocationAuthorizationStatus status =
                await _connectivity.getLocationServiceAuthorization();
            if (status == LocationAuthorizationStatus.notDetermined) {
              status =
                  await _connectivity.requestLocationServiceAuthorization();
            }
            if (status == LocationAuthorizationStatus.authorizedAlways ||
                status == LocationAuthorizationStatus.authorizedWhenInUse) {
              wifiName = await _connectivity.getWifiName();
            } else {
              wifiName = await _connectivity.getWifiName();
            }
          } else {
            wifiName = await _connectivity.getWifiName();
          }
        } on PlatformException catch (e) {
          print(e.toString());
          wifiName = "Failed to get Wifi Name";
        }

        try {
          if (Platform.isIOS) {
            LocationAuthorizationStatus status =
                await _connectivity.getLocationServiceAuthorization();
            if (status == LocationAuthorizationStatus.notDetermined) {
              status =
                  await _connectivity.requestLocationServiceAuthorization();
            }
            if (status == LocationAuthorizationStatus.authorizedAlways ||
                status == LocationAuthorizationStatus.authorizedWhenInUse) {
              wifiBSSID = await _connectivity.getWifiBSSID();
            } else {
              wifiBSSID = await _connectivity.getWifiBSSID();
            }
          } else {
            wifiBSSID = await _connectivity.getWifiBSSID();
          }
        } on PlatformException catch (e) {
          print(e.toString());
          wifiBSSID = "Failed to get Wifi BSSID";
        }

        try {
          wifiIP = await _connectivity.getWifiIP();
        } on PlatformException catch (e) {
          print(e.toString());
          wifiIP = "Failed to get Wifi IP";
        }

        setState(() {
          _connectionStatus = '$result\n';
        });
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.none:
        setState(() => _connectionStatus = result.toString());
        break;
      default:
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionStatus == 'ConnectivityResult.none') {
      return normalPlayer(context);
    } else {
      return youtubeWidget(context);
    }
  }

  @override
  Widget normalPlayer(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(child: VideoPlayerScreen()),
    );
  }

  Widget youtubeWidget(BuildContext context) {
    Orientation currentOrientation = MediaQuery.of(context).orientation;
    var screenSize = MediaQuery.of(context).size;
    if (currentOrientation == Orientation.portrait) {
      _ratio = screenSize.width / screenSize.height;
    } else {
      _ratio = screenSize.height / screenSize.width;
    }
    return Scaffold(
      key: _scaffoldKey,
      // appBar: AppBar(
      //   title: const Text('Basic AppBar'),
      // ),
      appBar: null,
      body: SwipeDetector(
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          child: ListView(
            padding: EdgeInsets.only(top: 0),
            children: [
              YoutubePlayer(
                controller: _controller,
                thumbnailUrl:
                    'https://www.tlcchiropractic.co.za/wp-content/uploads/2019/07/cropped-Blank-White-Image.jpg',
                showVideoProgressIndicator: false,
                aspectRatio: _ratio,
                onReady: onReady,
                onEnded: (data) {
                  _controller.load(videoIDs[videoIDs.indexWhere((element) =>
                              (element.youtubeID == data.videoId)) +
                          1]
                      .youtubeID);
                  _controller.seekTo(Duration(seconds: 30));
                  _showSnackBar('Next Video Started!');
                },
              ),
            ],
          ),
        ),
        onSwipeRight: () {
          _controller.pause();
          _showSnackBar('Next');
          _controller.load(videoIDs[videoIDs.indexWhere((element) =>
                      (element.youtubeID == _videoMetaData.videoId)) +
                  1]
              .youtubeID);
          _controller.seekTo(Duration(seconds: 30));
        },
        onSwipeLeft: () {
          _controller.pause();
          _showSnackBar('Previous');

          _controller.load(videoIDs[videoIDs.indexWhere((element) =>
                      (element.youtubeID == _videoMetaData.videoId)) -
                  1]
              .youtubeID);
          _controller.seekTo(Duration(seconds: 30));
        },
        swipeConfiguration: SwipeConfiguration(
            horizontalSwipeMaxHeightThreshold: 100.0,
            horizontalSwipeMinDisplacement: 5.0,
            horizontalSwipeMinVelocity: 1.0),
      ),
    );
  }

  void _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
      ),
    );
  }
}
