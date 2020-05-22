import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:swipedetector/swipedetector.dart';

class VideoPlayerScreen extends StatefulWidget {
  VideoPlayerScreen({Key key}) : super(key: key);
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  List<VideoPlayerController> _controllers = [];
  int index = 0;
  bool _changeLock = false;
  double _progress = 0;
  // VideoPlayerController _controllers;

  double _ratio = 16 / 9;
  double _scale = 16 / 9;
  Future<void> _initializeVideoPlayerFuture;
  var vidlist = ['assets/videos/test.mp4'];
  var currentIndexPosition = 0; // Position on the list

  @override
  void initState() {
    _initControllers();
    // _controller = VideoPlayerController.asset('assets/videos/Chika-ontube.mp4');
    // _initializeVideoPlayerFuture = _controller.initialize();
    // _controller.setLooping(false);
    super.initState();
  }

  @override
  void dispose() {
    _controllers[1].dispose();
    super.dispose();
  }

  _initControllers() {
    _controllers.add(null);
    for (int i = 0; i < vidlist.length; i++) {
      if (i == 2) {
        break;
      }
      _controllers.add(VideoPlayerController.asset(vidlist[i]));
    }
    attachListenerAndInit(_controllers[1]).then((_) {
      _controllers[1].play().then((_) {
        setState(() {});
      });
    });

    if (_controllers.length > 2) {
      attachListenerAndInit(_controllers[2]);
    }
  }

  Future<void> attachListenerAndInit(VideoPlayerController controller) async {
    if (!controller.hasListeners) {
      controller.addListener(() {
        int dur = controller.value.duration.inMilliseconds;
        int pos = controller.value.position.inMilliseconds;
        setState(() {
          if (dur <= pos) {
            _progress = 0;
          } else {
            _progress = (dur - (dur - pos)) / dur;
          }
        });
        if (dur - pos < 1) {
          controller.seekTo(Duration(milliseconds: 0));
          nextVideo();
        }
      });
    }
    await controller.initialize().then((_) {});
    return;
  }

  void previousVideo() {
    if (_changeLock) {
      return;
    }
    _changeLock = true;

    if (index == 0) {
      _changeLock = false;
      return;
    }
    _controllers[1]?.pause();
    index--;

    if (index != vidlist.length - 2) {
      _controllers.last?.dispose();
      _controllers.removeLast();
    }
    if (index != 0) {
      _controllers.insert(0, VideoPlayerController.network(vidlist[index - 1]));
      attachListenerAndInit(_controllers.first);
    } else {
      _controllers.insert(0, null);
    }

    _controllers[1].play().then((_) {
      setState(() {
        _changeLock = false;
      });
    });
  }

  void nextVideo() {
    if (_changeLock) {
      return;
    }
    _changeLock = true;
    if (index == vidlist.length - 1) {
      _changeLock = false;
      return;
    }
    _controllers[1]?.pause();
    index++;
    _controllers.first?.dispose();
    _controllers.removeAt(0);
    if (index != vidlist.length - 1) {
      _controllers.add(VideoPlayerController.network(vidlist[index + 1]));
      attachListenerAndInit(_controllers.last);
    }

    _controllers[1].play().then((_) {
      setState(() {
        _changeLock = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Orientation currentOrientation = MediaQuery.of(context).orientation;
    var screenSize = MediaQuery.of(context).size;
    if (currentOrientation == Orientation.portrait) {
      // _ratio = 9 / 16;
      _ratio = screenSize.width / screenSize.height;
      _scale = (screenSize.height / screenSize.width) *
          _controllers[1].value.aspectRatio;
    } else {
      // _ratio = 16 / 9;
      _ratio = screenSize.height / screenSize.width;
      _scale = _controllers[1].value.aspectRatio;
    }
    return Scaffold(
      appBar: null,
      body: SwipeDetector(
        child: Stack(
          children: <Widget>[
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  // aspectRatio: _controllers[1].value.aspectRatio,
                  width: _controllers[1].value.size?.width ?? 0,
                  height: _controllers[1].value.size?.height ?? 0,
                  child: VideoPlayer(
                    _controllers[1],
                  ),
                ),
              ),
            ),
          ],
        ),
        onSwipeRight: (nextVideo),
        onSwipeLeft: (previousVideo),
        swipeConfiguration: SwipeConfiguration(
            horizontalSwipeMaxHeightThreshold: 100.0,
            horizontalSwipeMinDisplacement: 5.0,
            horizontalSwipeMinVelocity: 5.0),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
