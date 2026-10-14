import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// ─────────────────────────────────────────────────────────────────────────────
// SebatDataManager  (:glance)
// Pure data-layer: Storage reads/writes + calculations only.
// Intentionally avoids Activity, SensorHistory, Attention – all non-glance APIs.
// Those operations live in SebatView.mc.
// ─────────────────────────────────────────────────────────────────────────────
(:glance)
class SebatDataManager {

    // ── Storage Keys ──────────────────────────────────────────────────────────
    private static const KEY_PACK_SIZE        as String = "packSize";
    private static const KEY_PACK_PRICE       as String = "packPrice";
    private static const KEY_PACK_LEFT        as String = "packLeft";
    private static const KEY_TODAY_COUNT      as String = "todayCount";
    private static const KEY_MONTH_COUNT      as String = "monthCount";
    private static const KEY_LAST_LOG_DAY     as String = "lastLogDay";
    private static const KEY_LAST_LOG_MONTH   as String = "lastLogMonth";
    private static const KEY_LAST_SMOKE_TIME  as String = "lastSmokeTime";
    private static const KEY_LAST_SMOKE_BASEHR as String = "lastSmokeBaseHr";
    private static const KEY_AVG_INTERVAL_SEC as String = "avgIntervalSec";
    private static const KEY_LAST_HR_SPIKE    as String = "lastHrSpike";
    private static const KEY_LAST_PEAK_STRESS as String = "lastPeakStress";
    private static const KEY_TODAY_EXTRA_BEATS as String = "todayExtraBeats";
    private static const KEY_PREV_SNAPSHOT    as String = "previousStateSnapshot";

    // ── Cached In-Memory Fields ───────────────────────────────────────────────
    private var _packSize        as Number = 16;
    private var _packPrice       as Number = 36000;
    private var _packLeft        as Number = 16;
    private var _todayCount      as Number = 0;
    private var _monthCount      as Number = 0;
    private var _lastLogDay      as Number = 0;
    private var _lastLogMonth    as Number = 0;
    private var _lastSmokeTime   as Number = 0;
    private var _lastSmokeBaseHr as Number = 75;
    private var _avgIntervalSec  as Number = 5400; // 90 min default
    private var _lastHrSpike     as Number = 0;
    private var _lastPeakStress  as Number = 0;
    private var _todayExtraBeats as Number = 0;

    // ── Constructor ───────────────────────────────────────────────────────────
    (:glance)
    function initialize() {
        loadAll();
    }

    // ── Load All State From Storage ───────────────────────────────────────────
    (:glance)
    function loadAll() as Void {
        var s = Application.Storage;

        var v = s.getValue(KEY_PACK_SIZE) as Number?;
        _packSize = (v != null) ? v : 16;

        v = s.getValue(KEY_PACK_PRICE) as Number?;
        _packPrice = (v != null) ? v : 36000;

        v = s.getValue(KEY_PACK_LEFT) as Number?;
        _packLeft = (v != null) ? v : _packSize;

        v = s.getValue(KEY_TODAY_COUNT) as Number?;
        _todayCount = (v != null) ? v : 0;

        v = s.getValue(KEY_MONTH_COUNT) as Number?;
        _monthCount = (v != null) ? v : 0;

        v = s.getValue(KEY_LAST_LOG_DAY) as Number?;
        _lastLogDay = (v != null) ? v : 0;

        v = s.getValue(KEY_LAST_LOG_MONTH) as Number?;
        _lastLogMonth = (v != null) ? v : 0;

        v = s.getValue(KEY_LAST_SMOKE_TIME) as Number?;
        _lastSmokeTime = (v != null) ? v : 0;

        v = s.getValue(KEY_LAST_SMOKE_BASEHR) as Number?;
        _lastSmokeBaseHr = (v != null) ? v : 75;

        v = s.getValue(KEY_AVG_INTERVAL_SEC) as Number?;
        _avgIntervalSec = (v != null) ? v : 5400;

        v = s.getValue(KEY_LAST_HR_SPIKE) as Number?;
        _lastHrSpike = (v != null) ? v : 0;

        v = s.getValue(KEY_LAST_PEAK_STRESS) as Number?;
        _lastPeakStress = (v != null) ? v : 0;

        v = s.getValue(KEY_TODAY_EXTRA_BEATS) as Number?;
        _todayExtraBeats = (v != null) ? v : 0;
    }

    // ── Getters ───────────────────────────────────────────────────────────────
    (:glance) function getPackSize()        as Number { return _packSize;        }
    (:glance) function getPackPrice()       as Number { return _packPrice;       }
    (:glance) function getPackLeft()        as Number { return _packLeft;        }
    (:glance) function getTodayCount()      as Number { return _todayCount;      }
    (:glance) function getMonthCount()      as Number { return _monthCount;      }
    (:glance) function getLastSmokeTime()   as Number { return _lastSmokeTime;   }
    (:glance) function getLastSmokeBaseHr() as Number { return _lastSmokeBaseHr; }
    (:glance) function getAvgIntervalSec()  as Number { return _avgIntervalSec;  }
    (:glance) function getLastHrSpike()     as Number { return _lastHrSpike;     }
    (:glance) function getLastPeakStress()  as Number { return _lastPeakStress;  }
    (:glance) function getTodayExtraBeats() as Number { return _todayExtraBeats; }

    // ── Setters ───────────────────────────────────────────────────────────────
    (:glance)
    function setLastHrSpike(v as Number) as Void {
        _lastHrSpike = v;
        Application.Storage.setValue(KEY_LAST_HR_SPIKE, v);
    }

    (:glance)
    function setLastPeakStress(v as Number) as Void {
        _lastPeakStress = v;
        Application.Storage.setValue(KEY_LAST_PEAK_STRESS, v);
    }

    (:glance)
    function setPackSize(size as Number) as Void {
        _packSize = size;
        Application.Storage.setValue(KEY_PACK_SIZE, _packSize);
    }

    (:glance)
    function setPackPrice(price as Number) as Void {
        _packPrice = price;
        Application.Storage.setValue(KEY_PACK_PRICE, _packPrice);
    }

    // ── Midnight Rollover ─────────────────────────────────────────────────────
    (:glance)
    function checkRollover() as Void {
        var now      = Time.now();
        var info     = Gregorian.info(now, Time.FORMAT_SHORT);
        var year     = info.year as Number;
        var month    = info.month as Number;
        var day      = info.day as Number;
        var currDay  = year * 10000 + month * 100 + day;
        var currMon  = month;

        if (_lastLogDay != 0 && currDay != _lastLogDay) {
            _todayCount      = 0;
            _todayExtraBeats = 0;
            Application.Storage.setValue(KEY_TODAY_COUNT,       _todayCount);
            Application.Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats);

            if (currMon != _lastLogMonth) {
                _monthCount = 0;
                Application.Storage.setValue(KEY_MONTH_COUNT, _monthCount);
            }
        }

        _lastLogDay   = currDay;
        _lastLogMonth = currMon;
        Application.Storage.setValue(KEY_LAST_LOG_DAY,   _lastLogDay);
        Application.Storage.setValue(KEY_LAST_LOG_MONTH, _lastLogMonth);
    }

    // ── Chain-Smoking Check (<30 min since last smoke) ────────────────────────
    (:glance)
    function isChainSmoking() as Boolean {
        if (_lastSmokeTime == 0) { return false; }
        var elapsed = Time.now().value().toNumber() - _lastSmokeTime;
        return (elapsed < 1800);
    }

    // ── Seconds Since Last Smoke ──────────────────────────────────────────────
    (:glance)
    function getSecondsSinceLastSmoke() as Number {
        if (_lastSmokeTime == 0) { return 0; }
        return Time.now().value().toNumber() - _lastSmokeTime;
    }

    // ── Recovery Phase  0=Red(<20m)  1=Orange(20-120m)  2=Green(>120m) ───────
    (:glance)
    function getRecoveryPhase() as Number {
        var e = getSecondsSinceLastSmoke();
        if (e == 0)   { return 0; }
        if (e < 1200) { return 0; }
        if (e < 7200) { return 1; }
        return 2;
    }

    // ── EMA Predicted Run-Out Clock "~HH:MM" ─────────────────────────────────
    (:glance)
    function getPredictedRunOutTime() as String {
        if (_packLeft <= 0)       { return "Habis"; }
        if (_avgIntervalSec <= 0) { return "--:--"; }

        var secUntilOut = _packLeft * _avgIntervalSec;
        var futureEpoch = Time.now().value().toNumber() + secUntilOut;
        var futureMom   = new Time.Moment(futureEpoch);
        var fi          = Gregorian.info(futureMom, Time.FORMAT_SHORT);
        return Lang.format("~$1$:$2$", [fi.hour.format("%02d"), fi.min.format("%02d")]);
    }

    // ── Format Elapsed "Xj Ym lalu" ──────────────────────────────────────────
    (:glance)
    function formatElapsed(seconds as Number) as String {
        if (seconds <= 0) { return "Baru saja"; }
        var h = seconds / 3600;
        var m = (seconds % 3600) / 60;
        if (h > 0) {
            return Lang.format("$1$j $2$m lalu", [h, m]);
        }
        return Lang.format("$1$ mnt lalu", [m]);
    }

    // ── Format Rupiah "Rp 36.000" ─────────────────────────────────────────────
    (:glance)
    function formatRupiah(amount as Number) as String {
        if (amount < 0)    { amount = 0; }
        if (amount < 1000) { return Lang.format("Rp $1$", [amount]); }
        var t = amount / 1000;
        var r = amount % 1000;
        if (t >= 1000) {
            var m2 = t / 1000;
            var t2 = t % 1000;
            return Lang.format("Rp $1$.$2$.$3$", [m2, t2.format("%03d"), r.format("%03d")]);
        }
        return Lang.format("Rp $1$.$2$", [t, r.format("%03d")]);
    }

    // ── Today / Monthly Cost ──────────────────────────────────────────────────
    (:glance)
    function getTodayCost() as Number {
        if (_packSize == 0) { return 0; }
        return _todayCount * (_packPrice / _packSize);
    }

    (:glance)
    function getMonthlyCost() as Number {
        if (_packSize == 0) { return 0; }
        return _monthCount * (_packPrice / _packSize);
    }

    // ── Snapshot Save (before auto-log, enables undo) ─────────────────────────
    (:glance)
    function saveSnapshot() as Void {
        var snap = {
            "packLeft"        => _packLeft,
            "todayCount"      => _todayCount,
            "monthCount"      => _monthCount,
            "lastSmokeTime"   => _lastSmokeTime,
            "lastSmokeBaseHr" => _lastSmokeBaseHr,
            "avgIntervalSec"  => _avgIntervalSec,
            "todayExtraBeats" => _todayExtraBeats
        } as Dictionary<String, Number>;
        Application.Storage.setValue(KEY_PREV_SNAPSHOT, snap);
    }

    // ── Snapshot Restore (undo) ───────────────────────────────────────────────
    (:glance)
    function restoreSnapshot() as Void {
        var snap = Application.Storage.getValue(KEY_PREV_SNAPSHOT) as Dictionary?;
        if (snap == null) { return; }

        var v = snap.get("packLeft") as Number?;
        if (v != null) { _packLeft = v; Application.Storage.setValue(KEY_PACK_LEFT, _packLeft); }

        v = snap.get("todayCount") as Number?;
        if (v != null) { _todayCount = v; Application.Storage.setValue(KEY_TODAY_COUNT, _todayCount); }

        v = snap.get("monthCount") as Number?;
        if (v != null) { _monthCount = v; Application.Storage.setValue(KEY_MONTH_COUNT, _monthCount); }

        v = snap.get("lastSmokeTime") as Number?;
        if (v != null) { _lastSmokeTime = v; Application.Storage.setValue(KEY_LAST_SMOKE_TIME, _lastSmokeTime); }

        v = snap.get("lastSmokeBaseHr") as Number?;
        if (v != null) { _lastSmokeBaseHr = v; Application.Storage.setValue(KEY_LAST_SMOKE_BASEHR, _lastSmokeBaseHr); }

        v = snap.get("avgIntervalSec") as Number?;
        if (v != null) { _avgIntervalSec = v; Application.Storage.setValue(KEY_AVG_INTERVAL_SEC, _avgIntervalSec); }

        v = snap.get("todayExtraBeats") as Number?;
        if (v != null) { _todayExtraBeats = v; Application.Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats); }
    }

    // ── Auto-Log One Cigarette (saves snapshot first) ─────────────────────────
    // Returns true if a new pack was auto-opened.
    (:glance)
    function autoLog(baseHr as Number) as Boolean {
        saveSnapshot();

        // EMA interval update (skip sleep gaps)
        if (_lastSmokeTime > 0) {
            var nowSec   = Time.now().value().toNumber();
            var interval = nowSec - _lastSmokeTime;
            if (interval >= 300 && interval <= 14400) {
                _avgIntervalSec = ((_avgIntervalSec * 7 + interval * 3) / 10).toNumber();
                Application.Storage.setValue(KEY_AVG_INTERVAL_SEC, _avgIntervalSec);
            }
        }

        // Decrement pack; auto-open if exhausted
        _packLeft = _packLeft - 1;
        var newPack = false;
        if (_packLeft <= 0) {
            _packLeft = _packSize - 1;
            newPack   = true;
        }
        Application.Storage.setValue(KEY_PACK_LEFT, _packLeft);

        // Counts
        _todayCount  = _todayCount  + 1;
        _monthCount  = _monthCount  + 1;
        Application.Storage.setValue(KEY_TODAY_COUNT,  _todayCount);
        Application.Storage.setValue(KEY_MONTH_COUNT,  _monthCount);

        // Smoke timestamp + baseline HR
        _lastSmokeTime   = Time.now().value().toNumber();
        _lastSmokeBaseHr = baseHr;
        Application.Storage.setValue(KEY_LAST_SMOKE_TIME,  _lastSmokeTime);
        Application.Storage.setValue(KEY_LAST_SMOKE_BASEHR, _lastSmokeBaseHr);

        // Extra beats (using spike from PREVIOUS smoke analysis)
        var spike = (_lastHrSpike > 0) ? _lastHrSpike : 12;
        _todayExtraBeats = _todayExtraBeats + (spike * 30);
        Application.Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats);

        return newPack;
    }

    // ── Manual Log (no snapshot / no undo) ───────────────────────────────────
    (:glance)
    function manualLog() as Boolean {
        if (_lastSmokeTime > 0) {
            var nowSec   = Time.now().value().toNumber();
            var interval = nowSec - _lastSmokeTime;
            if (interval >= 300 && interval <= 14400) {
                _avgIntervalSec = ((_avgIntervalSec * 7 + interval * 3) / 10).toNumber();
                Application.Storage.setValue(KEY_AVG_INTERVAL_SEC, _avgIntervalSec);
            }
        }

        _packLeft = _packLeft - 1;
        var newPack = false;
        if (_packLeft <= 0) {
            _packLeft = _packSize - 1;
            newPack   = true;
        }
        Application.Storage.setValue(KEY_PACK_LEFT, _packLeft);

        _todayCount = _todayCount + 1;
        _monthCount = _monthCount + 1;
        Application.Storage.setValue(KEY_TODAY_COUNT, _todayCount);
        Application.Storage.setValue(KEY_MONTH_COUNT, _monthCount);

        _lastSmokeTime = Time.now().value().toNumber();
        Application.Storage.setValue(KEY_LAST_SMOKE_TIME, _lastSmokeTime);

        var spike = (_lastHrSpike > 0) ? _lastHrSpike : 12;
        _todayExtraBeats = _todayExtraBeats + (spike * 30);
        Application.Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats);

        return newPack;
    }

    // ── Open New Pack ─────────────────────────────────────────────────────────
    (:glance)
    function openNewPack() as Void {
        _packLeft = _packSize;
        Application.Storage.setValue(KEY_PACK_LEFT, _packLeft);
    }

    // ── Remove One Log (manual correction -1) ─────────────────────────────────
    (:glance)
    function removeOneLog() as Void {
        if (_todayCount > 0) {
            _todayCount = _todayCount - 1;
            Application.Storage.setValue(KEY_TODAY_COUNT, _todayCount);
        }
        if (_monthCount > 0) {
            _monthCount = _monthCount - 1;
            Application.Storage.setValue(KEY_MONTH_COUNT, _monthCount);
        }
        if (_packLeft < _packSize) {
            _packLeft = _packLeft + 1;
            Application.Storage.setValue(KEY_PACK_LEFT, _packLeft);
        }
        if (_todayExtraBeats > 0) {
            var spike  = (_lastHrSpike > 0) ? _lastHrSpike : 12;
            var reduce = spike * 30;
            _todayExtraBeats = (_todayExtraBeats > reduce) ? (_todayExtraBeats - reduce) : 0;
            Application.Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats);
        }
    }

    // ── Reset Today's Counters ────────────────────────────────────────────────
    (:glance)
    function resetToday() as Void {
        _todayCount      = 0;
        _todayExtraBeats = 0;
        Application.Storage.setValue(KEY_TODAY_COUNT,       _todayCount);
        Application.Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats);
    }
}
