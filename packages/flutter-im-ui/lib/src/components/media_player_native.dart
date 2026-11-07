import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController localMediaPlayer(Uri source) =>
    VideoPlayerController.file(File.fromUri(source));
