package com.sfx.legacyvault.core.util

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object DateFormatters {
    private const val DISPLAY_FORMAT = "yyyy-MM-dd HH:mm:ss"
    private const val DATE_ONLY_FORMAT = "yyyy-MM-dd"
    private const val ISO_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

    val display: SimpleDateFormat
        get() = SimpleDateFormat(DISPLAY_FORMAT, Locale.getDefault())

    val dateOnly: SimpleDateFormat
        get() = SimpleDateFormat(DATE_ONLY_FORMAT, Locale.getDefault())

    val isoFormat: SimpleDateFormat
        get() = SimpleDateFormat(ISO_FORMAT, Locale.US)

    fun formatDisplay(epochSeconds: Long): String {
        return display.format(Date(epochSeconds * 1000))
    }

    fun formatDateOnly(epochSeconds: Long): String {
        return dateOnly.format(Date(epochSeconds * 1000))
    }

    fun epochSecondsToDate(epochSeconds: Long): Date {
        return Date(epochSeconds * 1000)
    }

    fun currentDateSeconds(): Long {
        return System.currentTimeMillis() / 1000
    }
}
