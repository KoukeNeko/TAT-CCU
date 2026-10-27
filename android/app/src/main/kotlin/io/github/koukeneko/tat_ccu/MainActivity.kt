package io.github.koukeneko.tat_ccu

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // A Googlebook or Chromebook gets the desktop UI
        // (lib/ui/core/desktop_mode.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tat_ccu/desktop")
            .setMethodCallHandler { call, result ->
                if (call.method == "pc") {
                    result.success(packageManager.hasSystemFeature("android.hardware.type.pc"))
                } else {
                    result.notImplemented()
                }
            }
    }
}
