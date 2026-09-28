package com.musick.app

import com.ryanheise.audioservice.AudioServiceActivity

// audio_service requires MainActivity to extend AudioServiceActivity
// (itself a FlutterFragmentActivity — still the v2 embedding) rather than
// the plain FlutterActivity, so its background service can bind back to
// the Flutter engine correctly for the mini-player/notification controls.
class MainActivity : AudioServiceActivity()
