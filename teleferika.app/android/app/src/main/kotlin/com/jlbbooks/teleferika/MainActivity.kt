package com.jlbbooks.teleferika

import android.content.Context
import android.location.GpsStatus
import android.location.LocationManager
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "teleferika.app/gps_info"
    private var locationManager: LocationManager? = null
    private var gpsStatusListener: GpsStatus.Listener? = null
    private var currentSatelliteCount: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSatelliteCount" -> {
                    val count = getSatelliteCount()
                    result.success(count)
                }
                "getFixQuality" -> {
                    val quality = getFixQuality()
                    result.success(quality)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up GPS status listener to track satellite count
        setupGpsStatusListener()
    }

    private fun setupGpsStatusListener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            setupGpsStatusListenerNougat()
        } else {
            setupGpsStatusListenerLegacy()
        }
    }

    @RequiresApi(Build.VERSION_CODES.N)
    private fun setupGpsStatusListenerNougat() {
        try {
            gpsStatusListener = GpsStatus.Listener { event ->
                when (event) {
                    GpsStatus.GPS_EVENT_STARTED -> {
                        // GPS started
                    }
                    GpsStatus.GPS_EVENT_STOPPED -> {
                        // GPS stopped
                        currentSatelliteCount = null
                    }
                    GpsStatus.GPS_EVENT_FIRST_FIX -> {
                        // First fix obtained
                        updateSatelliteCount()
                    }
                    GpsStatus.GPS_EVENT_SATELLITE_STATUS -> {
                        // Satellite status changed
                        updateSatelliteCount()
                    }
                }
            }
            locationManager?.registerGnssStatusCallback(object : android.location.GnssStatus.Callback() {
                override fun onSatelliteStatusChanged(status: android.location.GnssStatus) {
                    var count = 0
                    for (i in 0 until status.satelliteCount) {
                        if (status.usedInFix(i)) {
                            count++
                        }
                    }
                    currentSatelliteCount = count
                }
            })
        } catch (e: Exception) {
            // GPS status listener not available or permission denied
        }
    }

    @Suppress("DEPRECATION")
    private fun setupGpsStatusListenerLegacy() {
        try {
            gpsStatusListener = GpsStatus.Listener { event ->
                when (event) {
                    GpsStatus.GPS_EVENT_STARTED -> {
                        // GPS started
                    }
                    GpsStatus.GPS_EVENT_STOPPED -> {
                        // GPS stopped
                        currentSatelliteCount = null
                    }
                    GpsStatus.GPS_EVENT_FIRST_FIX -> {
                        // First fix obtained
                        updateSatelliteCount()
                    }
                    GpsStatus.GPS_EVENT_SATELLITE_STATUS -> {
                        // Satellite status changed
                        updateSatelliteCount()
                    }
                }
            }
            locationManager?.addGpsStatusListener(gpsStatusListener)
        } catch (e: Exception) {
            // GPS status listener not available or permission denied
        }
    }

    @Suppress("DEPRECATION")
    private fun updateSatelliteCount() {
        try {
            val gpsStatus = locationManager?.getGpsStatus(null)
            if (gpsStatus != null) {
                var count = 0
                val satellites = gpsStatus.satellites
                for (satellite in satellites) {
                    if (satellite.usedInFix()) {
                        count++
                    }
                }
                currentSatelliteCount = count
            }
        } catch (e: Exception) {
            // Error getting GPS status
        }
    }

    private fun getSatelliteCount(): Int? {
        return currentSatelliteCount
    }

    private fun getFixQuality(): Int? {
        // Try to determine fix quality from location provider status
        try {
            val isGpsEnabled = locationManager?.isProviderEnabled(LocationManager.GPS_PROVIDER) ?: false
            if (!isGpsEnabled) {
                return 0 // No fix
            }
            
            // Check if we have a recent location fix
            val lastKnownLocation = locationManager?.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            if (lastKnownLocation != null) {
                val timeSinceFix = System.currentTimeMillis() - lastKnownLocation.time
                // If fix is less than 5 seconds old, assume we have a GPS fix
                if (timeSinceFix < 5000) {
                    // Check accuracy to estimate fix quality
                    val accuracy = lastKnownLocation.accuracy
                    return when {
                        accuracy < 1.0 -> 1 // GPS Fix (high accuracy)
                        accuracy < 5.0 -> 1 // GPS Fix
                        else -> 1 // GPS Fix (lower quality)
                    }
                }
            }
            
            // If we have satellite count, we likely have some fix
            if (currentSatelliteCount != null && currentSatelliteCount!! > 0) {
                return 1 // GPS Fix
            }
            
            return 0 // No fix
        } catch (e: Exception) {
            return null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Clean up GPS status listener
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // GnssStatus.Callback is automatically unregistered
            } else {
                @Suppress("DEPRECATION")
                gpsStatusListener?.let {
                    locationManager?.removeGpsStatusListener(it)
                }
            }
        } catch (e: Exception) {
            // Ignore errors during cleanup
        }
    }
}
