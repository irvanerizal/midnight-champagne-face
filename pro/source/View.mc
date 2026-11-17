import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class MidnightChampagneView extends WatchUi.WatchFace {

    // ---- Palette -----------------------------------------------------------
    private const BG = 0x0B1020;
    private const CHAMPAGNE = 0xD8C3A5;
    private const MINUTE_TICK = 0x726A63;
    private const DATE = 0xB9A891;
    private const AOD_HANDS = 0x9A8A70;
    private const AOD_TICKS = 0x5F5648;
    private const SUBDIAL_TRACK = 0x1E2540;

    // Nudge the date vertically without touching the -0.255*w formula.
    private const DATE_Y_OFFSET = 0;

    // ---- Cached geometry (filled once in onLayout) -------------------------
    private var mCx as Number = 0;
    private var mCy as Number = 0;

    private var mHourLen as Number = 0;
    private var mMinuteLen as Number = 0;
    private var mDateY as Number = 0;
    private var mCapOuter as Number = 0;
    private var mCapInner as Number = 0;

    private var mMinuteTickPen as Number = 2;
    private var mHourTickPen as Number = 2;
    private var mHourHandPen as Number = 2;
    private var mMinuteHandPen as Number = 2;
    private var mAodHandPen as Number = 3;

    private var mSubX as Array<Number> = [];
    private var mSubY as Array<Number> = [];
    private var mSubRadius as Number = 0;
    private var mSubPen as Number = 2;
    private var mIconDy as Number = 0;
    private var mIconSize as Number = 0;
    private var mNumberDy as Number = 0;

    // Flat [x1, y1, x2, y2] groups - no allocation in onUpdate.
    private var mHourTicks as Array<Number> = [];
    private var mMinuteTicks as Array<Number> = [];

    private var mSleeping as Boolean = false;

    private var _dateFont as Graphics.FontType?;
    private var _subFont as Graphics.FontType?;

    public function initialize() {
        WatchFace.initialize();
    }

    public function onLayout(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        mCx = w / 2;
        mCy = h / 2;
        mHourLen = scaled(w, 0.189);
        mMinuteLen = scaled(w, 0.311);
        mDateY = mCy - scaled(w, 0.255);
        _dateFont = WatchUi.loadResource(Rez.Fonts.DateCinzel) as Graphics.FontType;
        if (_dateFont == null) {
            _dateFont = Graphics.FONT_XTINY;
        }
        _subFont = WatchUi.loadResource(Rez.Fonts.SubNumber) as Graphics.FontType;
        if (_subFont == null) {
            _subFont = Graphics.FONT_XTINY;
        }
        mCapOuter = scaled(w, 0.0236);
        mCapInner = scaled(w, 0.0153);

        mMinuteTickPen = atLeast(scaled(w, 0.0044), 2);
        mHourTickPen = atLeast(scaled(w, 0.0122), 2);
        mHourHandPen = atLeast(scaled(w, 0.0222), 2);
        mMinuteHandPen = atLeast(scaled(w, 0.0167), 2);
        mAodHandPen = atLeast(scaled(w, 0.0111), 3);

        // Subdial centers, radius and inner icon/number offsets.
        mSubX = [mCx - scaled(w, 0.2333), mCx + scaled(w, 0.2333), mCx];
        mSubY = [mCy + scaled(w, 0.0111), mCy + scaled(w, 0.0111),
                 mCy + scaled(w, 0.2333)];
        mSubRadius = scaled(w, 0.0833);
        mSubPen = atLeast(scaled(w, 0.0167), 2);
        mIconDy = scaled(w, 0.0306);
        mIconSize = scaled(w, 0.056);
        mNumberDy = scaled(w, 0.0283);

        // 12 hour ticks.
        var hourInner = scaled(w, 0.4167);
        var hourOuter = scaled(w, 0.4722);
        mHourTicks = new Array<Number>[12 * 4];
        for (var i = 0; i < 12; i += 1) {
            fillTick(mHourTicks, i * 4, i * 30.0, hourInner, hourOuter);
        }

        // 48 minute ticks (60 positions minus the 12 hour positions).
        var minuteInner = scaled(w, 0.4417);
        var minuteOuter = scaled(w, 0.4694);
        mMinuteTicks = new Array<Number>[48 * 4];
        var slot = 0;
        for (var i = 0; i < 60; i += 1) {
            if (i % 5 == 0) {
                continue;
            }
            fillTick(mMinuteTicks, slot * 4, i * 6.0, minuteInner, minuteOuter);
            slot += 1;
        }
    }

    public function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        dc.setColor(BG, BG);
        dc.clear();

        var greg = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var hour = greg.hour;
        var minute = greg.min;

        if (mSleeping) {
            drawAod(dc, hour, minute);
            return;
        }

        // 2. Minute ticks.
        dc.setColor(MINUTE_TICK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(mMinuteTickPen);
        for (var i = 0; i < mMinuteTicks.size(); i += 4) {
            dc.drawLine(mMinuteTicks[i], mMinuteTicks[i + 1],
                mMinuteTicks[i + 2], mMinuteTicks[i + 3]);
        }

        // 3. Hour ticks.
        dc.setColor(CHAMPAGNE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(mHourTickPen);
        for (var i = 0; i < mHourTicks.size(); i += 4) {
            dc.drawLine(mHourTicks[i], mHourTicks[i + 1],
                mHourTicks[i + 2], mHourTicks[i + 3]);
        }

        // 4. Subdials.
        drawSubdials(dc);

        // 5. Date.
        drawDate(dc, greg);

        // 6. Hour hand, 7. minute hand, 8. center cap.
        dc.setColor(CHAMPAGNE, Graphics.COLOR_TRANSPARENT);
        drawHand(dc, (hour % 12) * 30.0 + minute * 0.5, mHourLen, mHourHandPen, true);
        drawHand(dc, minute * 6.0, mMinuteLen, mMinuteHandPen, true);
        dc.fillCircle(mCx, mCy, mCapOuter);
        dc.setColor(BG, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mCx, mCy, mCapInner);
    }

    //! Always-on mode: quarter ticks plus two thin hands, nothing else.
    private function drawAod(dc as Dc, hour as Number, minute as Number) as Void {
        dc.setColor(AOD_TICKS, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(mHourTickPen);
        for (var q = 0; q < 4; q += 1) {
            var o = q * 3 * 4;   // hour indexes 0, 3, 6, 9
            dc.drawLine(mHourTicks[o], mHourTicks[o + 1],
                mHourTicks[o + 2], mHourTicks[o + 3]);
        }

        dc.setColor(AOD_HANDS, Graphics.COLOR_TRANSPARENT);
        drawHand(dc, (hour % 12) * 30.0 + minute * 0.5, mHourLen, mAodHandPen, false);
        drawHand(dc, minute * 6.0, mMinuteLen, mAodHandPen, false);
    }

    //! Three subdials: battery (left), steps (right), body battery (bottom).
    private function drawSubdials(dc as Dc) as Void {
        // Battery.
        var battery = null;
        if (Toybox has :System) {
            var stats = System.getSystemStats();
            if (stats != null) {
                battery = stats.battery;
            }
        }
        var batteryP = clamp01(battery);
        var batteryLevel = batteryP != null ? batteryP : 0.0;
        drawSubdial(dc, mSubX[0], mSubY[0], batteryP,
            battery != null ? Math.round(battery).toNumber().toString() : "--",
            :battery, battery != null ? CHAMPAGNE : MINUTE_TICK, batteryLevel);

        // Steps / step goal.
        var steps = null;
        var goal = null;
        if (Toybox has :ActivityMonitor) {
            var info = ActivityMonitor.getInfo();
            if (info != null) {
                steps = info.steps;
                goal = info.stepGoal;
            }
        }
        var stepProgress = null;
        if (steps != null && goal != null && goal > 0) {
            stepProgress = clamp01(steps.toFloat() / goal.toFloat());
        }
        drawSubdial(dc, mSubX[1], mSubY[1], stepProgress,
            steps != null ? stepsText(steps) : "--",
            :steps, steps != null ? CHAMPAGNE : MINUTE_TICK, 0.0);

        // Heart rate (beats per minute), arc scaled to 180 bpm.
        var hr = null;
        if ((Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory)) {
            var iter = SensorHistory.getHeartRateHistory({
                :period => 1,
                :order => SensorHistory.ORDER_NEWEST_FIRST
            });
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    hr = sample.data;
                }
            }
        }
        var hrProgress = null;
        if (hr != null) {
            hrProgress = clamp01(hr.toFloat() / 180.0);
        }
        drawSubdial(dc, mSubX[2], mSubY[2], hrProgress,
            hr != null ? Math.round(hr).toNumber().toString() : "--",
            :heart, hr != null ? CHAMPAGNE : MINUTE_TICK, 0.0);
    }

    //! One subdial: track, progress arc, icon and value text.
    private function drawSubdial(dc as Dc, sx as Number, sy as Number,
            progress as Float?, text as String, kind as Symbol,
            iconColor as Number, level as Numeric) as Void {
        dc.setColor(SUBDIAL_TRACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(mSubPen);
        dc.drawCircle(sx, sy, mSubRadius);

        if (progress != null) {
            var p = progress as Float;
            if (p >= 1.0) {
                dc.setColor(CHAMPAGNE, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(sx, sy, mSubRadius);
            } else if (p > 0.0) {
                var endAngle = 90.0 - 360.0 * p;
                while (endAngle < 0.0) {
                    endAngle += 360.0;
                }
                dc.setColor(CHAMPAGNE, Graphics.COLOR_TRANSPARENT);
                dc.drawArc(sx, sy, mSubRadius, Graphics.ARC_CLOCKWISE, 90, endAngle);
            }
        }

        Icons.draw(dc, kind, sx, sy - mIconDy, mIconSize, iconColor, level);

        dc.setColor(CHAMPAGNE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sx, sy + mNumberDy, _subFont as Graphics.FontType, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function clamp01(value as Numeric?) as Float? {
        if (value == null) {
            return null;
        }
        var v = value.toFloat();
        if (v <= 0.0) {
            return 0.0;
        }
        if (v >= 1.0) {
            return 1.0;
        }
        return v;
    }

    private function stepsText(steps as Number) as String {
        if (steps >= 1000) {
            var tenths = Math.round(steps / 100.0).toNumber();
            return (tenths / 10).toString() + "." + (tenths % 10).toString() + "k";
        }
        return steps.toString();
    }

    private function drawDate(dc as Dc, greg as Gregorian.Info) as Void {
        var dayOfWeek = greg.day_of_week;
        var prefix;
        if (dayOfWeek instanceof String) {
            prefix = (dayOfWeek as String).toUpper();
        } else {
            prefix = (dayOfWeek as Number).toString();
        }
        var text = (prefix + " " + greg.day.toString()).toUpper();

        dc.setColor(DATE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mCx, mDateY + DATE_Y_OFFSET, _dateFont as Graphics.FontType, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Hand from the center outwards; optionally rounded with a tip circle.
    private function drawHand(dc as Dc, angleDeg as Numeric, length as Number,
            pen as Number, withTip as Boolean) as Void {
        var radians = angleDeg * Math.PI / 180.0;
        var x = Math.round(mCx + length * Math.sin(radians)).toNumber();
        var y = Math.round(mCy - length * Math.cos(radians)).toNumber();

        dc.setPenWidth(pen);
        dc.drawLine(mCx, mCy, x, y);
        if (withTip) {
            dc.fillCircle(x, y, pen / 2.0);
        }
    }

    //! Write one radial segment into a flat [x1, y1, x2, y2] array.
    private function fillTick(target as Array<Number>, offset as Number,
            angleDeg as Numeric, inner as Numeric, outer as Numeric) as Void {
        var radians = angleDeg * Math.PI / 180.0;
        var sinA = Math.sin(radians);
        var cosA = Math.cos(radians);

        target[offset] = Math.round(mCx + inner * sinA).toNumber();
        target[offset + 1] = Math.round(mCy - inner * cosA).toNumber();
        target[offset + 2] = Math.round(mCx + outer * sinA).toNumber();
        target[offset + 3] = Math.round(mCy - outer * cosA).toNumber();
    }

    //! Ratio of the screen dimension, rounded to whole pixels.
    private function scaled(dimension as Number, ratio as Numeric) as Number {
        return Math.round(ratio * dimension).toNumber();
    }

    private function atLeast(value as Number, minimum as Number) as Number {
        return value < minimum ? minimum : value;
    }

    public function onEnterSleep() as Void {
        mSleeping = true;
        WatchUi.requestUpdate();
    }

    public function onExitSleep() as Void {
        mSleeping = false;
        WatchUi.requestUpdate();
    }
}
