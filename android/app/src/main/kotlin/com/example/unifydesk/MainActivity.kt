package com.example.unifydesk

import android.content.Context
import android.net.ConnectivityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "unifydesk/network")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"isActiveNetworkMetered" -> {
						try {
							val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
							val metered = cm.isActiveNetworkMetered
							result.success(metered)
						} catch (e: Exception) {
							result.error("platform_error", e.message, null)
						}
					}
					else -> result.notImplemented()
				}
			}
	}
}
