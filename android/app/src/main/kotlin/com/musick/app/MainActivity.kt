package com.musick.app

import io.flutter.embedding.android.FlutterActivity

// Extending io.flutter.embedding.android.FlutterActivity (v2 embedding).
// The old/deleted v1 embedding was io.flutter.app.FlutterActivity — a
// different package. This file was missing from the previous drop, which
// is what triggered "Build failed due to use of deleted Android v1
// embedding": Flutter's tooling couldn't find a v2 activity class at all.
class MainActivity : FlutterActivity()
