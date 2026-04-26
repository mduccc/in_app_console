package com.example.iac_performance_overlay_ext

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/** IacPerformanceOverlayExtPlugin */
class IacPerformanceOverlayExtPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    // Previous snapshot for CPU delta computation.
    private var lastAppCpuJiffies: Long = 0L
    private var lastWallMs: Long = 0L

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "iac_performance_overlay_ext")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getCpuUsage" -> result.success(getCpuUsage())
            "getMemoryInfo" -> result.success(getMemoryInfo())
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // -------------------------------------------------------------------------
    // CPU — reads /proc/self/stat (app-process jiffies vs wall clock)
    //
    // Using /proc/stat (system-wide) fails on emulators because the
    // virtualised CPU jiffies barely advance relative to wall time, making
    // every delta round to 0.  /proc/self/stat reflects only this process and
    // tracks accurately against real elapsed time.
    // -------------------------------------------------------------------------

    /**
     * Reads utime + stime from /proc/self/stat.
     *
     * The stat file format is:
     *   pid (name) state ppid pgrp ... utime stime ...
     * The process name can contain spaces, so we skip past the last ')'.
     * After ')': fields are space-separated starting at index 0 = state.
     *   index 11 = utime, index 12 = stime  (0-based after ')')
     */
    private fun readAppCpuJiffies(): Long? {
        return try {
            val text = File("/proc/self/stat").readText()
            val closeParen = text.lastIndexOf(')')
            if (closeParen < 0) return null
            val fields = text.substring(closeParen + 2).trim().split(" ")
            if (fields.size < 13) return null
            val utime = fields[11].toLong()
            val stime = fields[12].toLong()
            utime + stime
        } catch (_: Exception) {
            null
        }
    }

    private fun getCpuUsage(): Double {
        val currentJiffies = readAppCpuJiffies() ?: return 0.0
        val currentWall = System.currentTimeMillis()

        val prevJiffies = lastAppCpuJiffies
        val prevWall = lastWallMs
        lastAppCpuJiffies = currentJiffies
        lastWallMs = currentWall

        if (prevWall == 0L) return 0.0

        val wallDeltaMs = currentWall - prevWall
        if (wallDeltaMs <= 0) return 0.0

        // USER_HZ is 100 on Android: 100 jiffies = 1 CPU-second
        val cpuDeltaSec = (currentJiffies - prevJiffies) / 100.0
        val wallDeltaSec = wallDeltaMs / 1000.0

        val numCores = Runtime.getRuntime().availableProcessors().toDouble()
        return (cpuDeltaSec / wallDeltaSec * 100.0 / numCores).coerceIn(0.0, 100.0)
    }

    // -------------------------------------------------------------------------
    // Memory
    // -------------------------------------------------------------------------

    private fun getMemoryInfo(): Map<String, Long> {
        val actManager =
            context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val sysInfo = ActivityManager.MemoryInfo()
        actManager.getMemoryInfo(sysInfo)

        // App resident set size (PSS in KB → bytes)
        val appMemInfo = Debug.MemoryInfo()
        Debug.getMemoryInfo(appMemInfo)
        val usedMem = appMemInfo.totalPss.toLong() * 1024L

        return mapOf(
            "usedMem" to usedMem,
            "totalMem" to sysInfo.totalMem,
        )
    }
}
