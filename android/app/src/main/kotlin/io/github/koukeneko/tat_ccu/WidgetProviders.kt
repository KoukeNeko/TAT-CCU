package io.github.koukeneko.tat_ccu

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONException
import org.json.JSONObject

// Home screen widgets (design/round-11/home-widgets.html). The app writes what
// they show as frames (lib/ui/home_widgets); these only pick the current frame
// and count the minutes left in a class.

/** The dark tones of lib/ui/core/theme.dart (Tones.of(Brightness.dark)). */
private enum class Tone(val background: Int, val ink: Int) {
  LILAC(R.drawable.widget_bg_lilac, 0xFFEADDFF.toInt()),
  MINT(R.drawable.widget_bg_mint, 0xFFC4EED0.toInt()),
  PEACH(R.drawable.widget_bg_peach, 0xFFFFDBCB.toInt()),
  SUN(R.drawable.widget_bg_sun, 0xFFFFE08A.toInt()),
  CARD(R.drawable.widget_bg_card, 0xFFF1E3DD.toInt()),
}

private const val MUTE = 0xFFB09A94.toInt()

internal class WidgetData(json: JSONObject) {
  val signedIn = json.getBoolean("signedIn")
  val labels: JSONObject = json.getJSONObject("labels")
  private val frames = json.getJSONArray("frames")

  /** The last frame that has begun, or the first while none has. */
  fun frame(now: Long = System.currentTimeMillis()): JSONObject? {
    var current = if (frames.length() > 0) frames.getJSONObject(0) else null
    for (i in 1 until frames.length()) {
      val f = frames.getJSONObject(i)
      if (f.getLong("at") > now) break
      current = f
    }
    return current
  }

  fun label(key: String): String = labels.getString(key)

  companion object {
    fun load(prefs: SharedPreferences): WidgetData? {
      val json = prefs.getString("widget_data", null) ?: return null
      return try {
        WidgetData(JSONObject(json))
      } catch (e: JSONException) {
        Log.e("TatWidgets", "widget data", e)
        null
      }
    }
  }
}

/** JSON null comes back from optString as "null". */
private fun JSONObject.str(key: String): String? = if (isNull(key)) null else getString(key)

private fun RemoteViews.text(id: Int, value: String?) {
  setTextViewText(id, value ?: "")
  setViewVisibility(id, if (value.isNullOrEmpty()) View.GONE else View.VISIBLE)
}

private fun RemoteViews.tone(root: Int, tone: Tone, vararg ids: Int) {
  setInt(root, "setBackgroundResource", tone.background)
  for (id in ids) setTextColor(id, tone.ink)
}

private fun RemoteViews.bar(progress: Double?, ink: Int) {
  if (progress == null) return setViewVisibility(R.id.bar, View.GONE)
  setViewVisibility(R.id.bar, View.VISIBLE)
  setProgressBar(R.id.bar, 1000, (progress.coerceIn(0.0, 1.0) * 1000).toInt(), false)
  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
    setColorStateList(R.id.bar, "setProgressTintList", ColorStateList.valueOf(ink))
  }
}

private fun minutesLeft(cls: JSONObject): Int =
    ((cls.getLong("end") - System.currentTimeMillis() + 59_999) / 60_000).toInt().coerceAtLeast(0)

private fun classTone(cls: JSONObject) =
    when {
      cls.has("end") -> Tone.LILAC
      cls.has("name") -> Tone.MINT
      else -> Tone.CARD
    }

/** Draws every instance from the current frame and opens the app on a tap. */
abstract class TatWidget : HomeWidgetProvider() {
  internal abstract fun render(
      context: Context,
      data: WidgetData?,
      frame: JSONObject?,
      wide: Boolean,
  ): RemoteViews

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val data = WidgetData.load(widgetData)
    val frame = data?.frame()
    for (id in appWidgetIds) {
      val wide =
          appWidgetManager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) >= 200
      val views = render(context, data, frame, wide)
      views.setOnClickPendingIntent(
          R.id.root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
  }

  /** The small block with only a title and a message: signed out, nothing due. */
  internal fun notice(context: Context, title: String, text: String?): RemoteViews =
      RemoteViews(context.packageName, R.layout.widget_small).apply {
        tone(R.id.root, Tone.CARD, R.id.title)
        setTextColor(R.id.header, MUTE)
        text(R.id.header, title)
        text(R.id.big, null)
        text(R.id.unit, null)
        text(R.id.title, text)
        text(R.id.detail, null)
        bar(null, 0)
      }
}

private val smallTexts = intArrayOf(R.id.header, R.id.sub, R.id.big, R.id.unit, R.id.title, R.id.detail, R.id.after)

class NextClassWidget : TatWidget() {
  override fun render(context: Context, data: WidgetData?, frame: JSONObject?, wide: Boolean): RemoteViews {
    if (data == null || frame == null) return notice(context, "", null)
    if (!data.signedIn) return notice(context, data.label("nextClass"), data.label("signedOut"))
    val cls = frame.getJSONObject("class")
    return RemoteViews(context.packageName, R.layout.widget_small).apply {
      val tone = classTone(cls)
      tone(R.id.root, tone, *smallTexts)
      text(R.id.header, cls.getString("label"))
      text(R.id.unit, null)
      text(R.id.title, cls.str("name"))
      if (cls.has("end")) {
        text(R.id.sub, null)
        text(R.id.big, null)
        text(R.id.detail, listOfNotNull(cls.str("room"), cls.str("until")).joinToString("・"))
        val start = cls.getLong("start")
        val end = cls.getLong("end")
        bar((System.currentTimeMillis() - start).toDouble() / (end - start), tone.ink)
      } else {
        text(R.id.sub, cls.str("sub"))
        text(R.id.big, cls.str("time"))
        text(R.id.detail, cls.str("room"))
        bar(null, 0)
      }
      text(R.id.after, null)
    }
  }
}

class TodayWidget : TatWidget() {
  override fun render(context: Context, data: WidgetData?, frame: JSONObject?, wide: Boolean): RemoteViews {
    if (data == null || frame == null) return notice(context, "", null)
    val day = frame.getJSONObject("day")
    if (!data.signedIn) return notice(context, day.getString("date"), data.label("signedOut"))
    return RemoteViews(context.packageName, R.layout.widget_today).apply {
      text(R.id.header, day.getString("date"))
      text(R.id.big, day.getInt("count").toString())
      text(R.id.unit, data.label("classes"))
      text(R.id.title, day.getString("headline"))
      removeAllViews(R.id.rows)
      val rows = day.getJSONArray("rows")
      if (rows.length() == 0) {
        // After the day's classes: the next school day's first one.
        val cls = frame.getJSONObject("class")
        if (cls.has("name")) {
          addView(R.id.rows, slotRow(context, cls.str("time"), cls.getString("name"),
              listOfNotNull(cls.str("sub"), cls.str("room")).joinToString("・"), cls.str("color"), false))
        }
      }
      for (i in 0 until minOf(3, rows.length())) {
        val r = rows.getJSONObject(i)
        addView(R.id.rows, slotRow(context, r.str("time"), r.getString("name"), r.str("room"), r.str("color"), r.optBoolean("now")))
      }
    }
  }
}

private fun slotRow(context: Context, time: String?, name: String, room: String?, color: String?, now: Boolean) =
    RemoteViews(context.packageName, R.layout.widget_row).apply {
      text(R.id.time, time)
      setTextColor(R.id.time, if (now) 0xFFD0BCFF.toInt() else Tone.CARD.ink)
      text(R.id.name, name)
      text(R.id.room, room)
      setInt(R.id.strip, "setColorFilter", color?.let(Color::parseColor) ?: MUTE)
    }

private fun dueRow(context: Context, row: JSONObject, ink: Int) =
    RemoteViews(context.packageName, R.layout.widget_due_row).apply {
      text(R.id.name, row.getString("name"))
      text(R.id.course, row.getString("course"))
      text(R.id.`when`, row.getString("when"))
      for (id in intArrayOf(R.id.name, R.id.course, R.id.`when`)) setTextColor(id, ink)
    }

class OverviewWidget : TatWidget() {
  override fun render(context: Context, data: WidgetData?, frame: JSONObject?, wide: Boolean): RemoteViews {
    if (data == null || frame == null) return notice(context, "", null)
    val day = frame.getJSONObject("day")
    if (!data.signedIn) return notice(context, day.getString("date"), data.label("signedOut"))
    val cls = frame.getJSONObject("class")
    return RemoteViews(context.packageName, R.layout.widget_overview).apply {
      val tone = classTone(cls)
      // On the card background the hero block needs a lighter surface.
      setInt(R.id.hero, "setBackgroundResource", if (tone == Tone.CARD) R.drawable.widget_bg_high else tone.background)
      for (id in intArrayOf(R.id.header, R.id.title, R.id.detail, R.id.big, R.id.unit)) setTextColor(id, tone.ink)
      val inClass = cls.has("end")
      text(R.id.header, listOfNotNull(cls.getString("label"), if (inClass) cls.str("until") else cls.str("sub")).joinToString("・"))
      text(R.id.title, cls.str("name") ?: day.getString("headline"))
      text(R.id.detail, cls.str("room"))
      text(R.id.big, if (inClass) minutesLeft(cls).toString() else cls.str("time"))
      text(R.id.unit, if (inClass) data.label("minutes") else null)

      removeAllViews(R.id.rows)
      val rows = day.getJSONArray("rows")
      var later = 0
      for (i in 0 until rows.length()) {
        val r = rows.getJSONObject(i)
        if (r.optBoolean("now") || r.str("time") == cls.str("time") || later == 3) continue
        addView(R.id.rows, slotRow(context, r.str("time"), r.getString("name"), r.str("room"), r.str("color"), false))
        later++
      }
      text(R.id.upcoming, if (later > 0) data.label("upcoming") else null)

      text(R.id.due_header, data.label("dueThisWeek"))
      removeAllViews(R.id.due_rows)
      val due = frame.getJSONObject("due").getJSONArray("rows")
      for (i in 0 until minOf(if (later > 0) 2 else 3, due.length())) {
        addView(R.id.due_rows, dueRow(context, due.getJSONObject(i), Tone.CARD.ink))
      }
      text(R.id.due_empty, if (due.length() == 0) data.label("nothingDue") else null)
    }
  }
}

class DueWidget : TatWidget() {
  override fun render(context: Context, data: WidgetData?, frame: JSONObject?, wide: Boolean): RemoteViews {
    if (data == null || frame == null) return notice(context, "", null)
    if (!data.signedIn) return notice(context, data.label("toDo"), data.label("signedOut"))
    val due = frame.getJSONObject("due")
    val rows = due.getJSONArray("rows")
    if (rows.length() == 0) return notice(context, data.label("toDo"), data.label("nothingDue"))
    val count = due.getInt("count")
    if (wide) {
      return RemoteViews(context.packageName, R.layout.widget_due).apply {
        text(R.id.header, data.label("dueThisWeek"))
        text(R.id.count, "$count ${data.label("items")}")
        removeAllViews(R.id.rows)
        for (i in 0 until minOf(3, rows.length())) addView(R.id.rows, dueRow(context, rows.getJSONObject(i), Tone.PEACH.ink))
      }
    }
    val first = rows.getJSONObject(0)
    return RemoteViews(context.packageName, R.layout.widget_small).apply {
      tone(R.id.root, Tone.PEACH, *smallTexts)
      text(R.id.header, data.label("toDo"))
      text(R.id.sub, null)
      text(R.id.big, count.toString())
      text(R.id.unit, data.label("items"))
      text(R.id.title, first.getString("name"))
      text(R.id.detail, first.getString("when"))
      bar(null, 0)
      text(R.id.after, null)
    }
  }
}

class CountdownWidget : TatWidget() {
  override fun render(context: Context, data: WidgetData?, frame: JSONObject?, wide: Boolean): RemoteViews {
    if (data == null || frame == null) return notice(context, "", null)
    val c = frame.optJSONObject("countdown")
        ?: return notice(context, data.label("countdown"), data.label("countdownEnded"))
    return RemoteViews(context.packageName, R.layout.widget_small).apply {
      tone(R.id.root, Tone.SUN, *smallTexts)
      text(R.id.header, data.label("countdown"))
      text(R.id.sub, null)
      text(R.id.big, c.getString("value"))
      text(R.id.unit, c.str("unit"))
      text(R.id.title, c.getString("title"))
      text(R.id.detail, c.getString("date"))
      bar(if (c.has("progress")) c.getDouble("progress") else null, Tone.SUN.ink)
      text(R.id.after, c.str("week"))
    }
  }
}
