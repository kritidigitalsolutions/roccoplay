package com.roccoplay.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.HashMap

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 🔐 FULL APP PROTECTION
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.roccoplay.app/proxy").setMethodCallHandler { call, result ->
            if (call.method == "getSystemProxy") {
                val proxyMap = HashMap<String, Any?>()
                val host = System.getProperty("http.proxyHost")
                val port = System.getProperty("http.proxyPort")

                if (!host.isNullOrEmpty()) {
                    proxyMap["host"] = host
                    proxyMap["port"] = port?.toIntOrNull() ?: 8080
                } else {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        val cm = getSystemService(android.content.Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
                        val proxyInfo = cm.defaultProxy
                        if (proxyInfo != null && !proxyInfo.host.isNullOrEmpty()) {
                            proxyMap["host"] = proxyInfo.host
                            proxyMap["port"] = proxyInfo.port
                        }
                    }
                }
                result.success(proxyMap)
            } else {
                result.notImplemented()
            }
        }
    }
}
