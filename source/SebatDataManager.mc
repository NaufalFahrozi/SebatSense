import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:glance)
class SebatDataManager {

    private static const KEY_PACK_SIZE         as String = "packSize";
    private static const KEY_PACK_PRICE        as String = "packPrice";
    private static const KEY_PACK_LEFT         as String = "packLeft";
    private static const KEY_TODAY_COUNT       as String = "todayCount";
    private static const KEY_MONTH_COUNT       as String = "monthCount";
    private static const KEY_LAST_LOG_DAY      as String = "lastLogDay";
    private static const KEY_LAST_LOG_MONTH    as String = "lastLogMonth";
    private static const KEY_LAST_SMOKE_TIME   as String = "lastSmokeTime";
    private static const KEY_LAST_SMOKE_BASEHR as String = "lastSmokeBaseHr";
    private static const KEY_AVG_INTERVAL_SEC  as String = "avgIntervalSec";
    private static const KEY_LAST_HR_SPIKE     as String = "lastHrSpike";
    private static const KEY_LAST_PEAK_STRESS  as String = "lastPeakStress";
    private static const KEY_TODAY_EXTRA_BEATS as String = "todayExtraBeats";
    private static const KEY_PREV_SNAPSHOT     as String = "previousStateSnapshot";

    private var _packSize        as Number = 16;
    private var _packPrice       as Number = 36000;
    private var _packLeft        as Number = 16;
    private var _todayCount      as Number = 0;
    private var _monthCount      as Number = 0;
    private var _lastLogDay      as Number = 0;
    private var _lastLogMonth    as Number = 0;
    private var _lastSmokeTime   as Number = 0;
    private var _lastSmokeBaseHr as Number = 75;
    private var _avgIntervalSec  as Number = 5400;
    private var _lastHrSpike     as Number = 0;
    private var _lastPeakStress  as Number = 0;
    private var _todayExtraBeats as Number = 0;

    function initialize() {
        loadAll();
    }

    function loadAll() as Void {
        var v = Storage.getValue(KEY_PACK_SIZE) as Number?;
        _packSize = (v != null) ? v : 16;

        v = Storage.getValue(KEY_PACK_PRICE) as Number?;
        _packPrice = (v != null) ? v : 36000;

        v = Storage.getValue(KEY_PACK_LEFT) as Number?;
        _packLeft = (v != null) ? v : _packSize;

        v = Storage.getValue(KEY_TODAY_COUNT) as Number?;
        _todayCount = (v != null) ? v : 0;

        v = Storage.getValue(KEY_MONTH_COUNT) as Number?;
        _monthCount = (v != null) ? v : 0;

        v = Storage.getValue(KEY_LAST_LOG_DAY) as Number?;
        _lastLogDay = (v != null) ? v : 0;

        v = Storage.getValue(KEY_LAST_LOG_MONTH) as Number?;
        _lastLogMonth = (v != null) ? v : 0;

        v = Storage.getValue(KEY_LAST_SMOKE_TIME) as Number?;
        _lastSmokeTime = (v != null) ? v : 0;

        v = Storage.getValue(KEY_LAST_SMOKE_BASEHR) as Number?;
        _lastSmokeBaseHr = (v != null) ? v : 75;

        v = Storage.getValue(KEY_AVG_INTERVAL_SEC) as Number?;
        _avgIntervalSec = (v != null) ? v : 5400;

        v = Storage.getValue(KEY_LAST_HR_SPIKE) as Number?;
        _lastHrSpike = (v != null) ? v : 0;

        v = Storage.getValue(KEY_LAST_PEAK_STRESS) as Number?;
        _lastPeakStress = (v != null) ? v : 0;

        v = Storage.getValue(KEY_TODAY_EXTRA_BEATS) as Number?;
        _todayExtraBeats = (v != null) ? v : 0;
    }

    function getPackSize() as Number        { return _packSize; }
    function getPackPrice() as Number       { return _packPrice; }
    function getPackLeft() as Number        { return _packLeft; }
    function getTodayCount() as Number      { return _todayCount; }
    function getMonthCount() as Number      { return _monthCount; }
    function getLastSmokeTime() as Number   { return _lastSmokeTime; }
    function getLastSmokeBaseHr() as Number { return _lastSmokeBaseHr; }
    function getAvgIntervalSec() as Number  { return _avgIntervalSec; }
    function getLastHrSpike() as Number     { return _lastHrSpike; }
    function getLastPeakStress() as Number  { return _lastPeakStress; }
    function getTodayExtraBeats() as Number { return _todayExtraBeats; }

    function setLastHrSpike(v as Number) as Void {
        _lastHrSpike = v;
        Storage.setValue(KEY_LAST_HR_SPIKE, v);
    }

    function setLastPeakStress(v as Number) as Void {
        _lastPeakStress = v;
        Storage.setValue(KEY_LAST_PEAK_STRESS, v);
    }

    function setPackSize(size as Number) as Void {
        _packSize = size;
        Storage.setValue(KEY_PACK_SIZE, _packSize);
    }

    function setPackPrice(price as Number) as Void {
        _packPrice = price;
        Storage.setValue(KEY_PACK_PRICE, _packPrice);
    }

    function checkRollover() as Void {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var year = info.year as Number;
        var month = info.month as Number;
        var day = info.day as Number;
        var currDay = (year * 10000) + (month * 100) + day;
        var currMon = month;

        if (_lastLogDay != currDay) {
            if (_lastLogDay != 0) {
                _todayCount = 0;
                _todayExtraBeats = 0;
                Storage.setValue(KEY_TODAY_COUNT, _todayCount);
                Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats);

                if (currMon != _lastLogMonth) {
                    _monthCount = 0;
                    Storage.setValue(KEY_MONTH_COUNT, _monthCount);
                }
            }
            _lastLogDay = currDay;
            _lastLogMonth = currMon;
            Storage.setValue(KEY_LAST_LOG_DAY, _lastLogDay);
            Storage.setValue(KEY_LAST_LOG_MONTH, _lastLogMonth);
        }
    }

    function isChainSmoking() as Boolean {
        if (_lastSmokeTime <= 0) { return false; }
        var elapsed = Time.now().value().toNumber() - _lastSmokeTime;
        return (elapsed >= 0 && elapsed < 1800);
    }

    function getSecondsSinceLastSmoke() as Number {
        if (_lastSmokeTime <= 0) { return -1; }
        var diff = Time.now().value().toNumber() - _lastSmokeTime;
        return (diff >= 0) ? diff : 0;
    }

    function getRecoveryPhase() as Number {
        var e = getSecondsSinceLastSmoke();
        if (e < 0) { return 2; }      // Belum merokok = Fase 2 (Hijau / Aman)
        if (e < 1200) { return 0; }   // < 20 menit = Fase 0 (Merah / HR Naik)
        if (e < 7200) { return 1; }   // 20-120 menit = Fase 1 (Oranye / CO Tinggi)
        return 2;                     // > 120 menit = Fase 2 (Hijau / Pulih)
    }

    function getPredictedRunOutTime() as String {
        if (_packLeft <= 0) { return "Habis"; }
        if (_avgIntervalSec <= 0) { return "--:--"; }

        var secUntilOut = _packLeft * _avgIntervalSec;
        var futureEpoch = Time.now().value().toNumber() + secUntilOut;
        var futureMom = new Time.Moment(futureEpoch);
        var fi = Gregorian.info(futureMom, Time.FORMAT_SHORT);
        return Lang.format("~$1$:$2$", [fi.hour.format("%02d"), fi.min.format("%02d")]);
    }

    function formatElapsed(seconds as Number) as String {
        if (seconds < 0) { return "Belum sebat"; }
        if (seconds < 60) { return "Baru saja"; }
        var h = seconds / 3600;
        var m = (seconds % 3600) / 60;
        if (h > 0) {
            return Lang.format("$1$j $2$m lalu", [h, m]);
        }
        return Lang.format("$1$m lalu", [m]);
    }

    function formatRupiah(amount as Number) as String {
        if (amount < 0) { amount = 0; }
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

    function getTodayCost() as Number {
        if (_packSize <= 0) { return 0; }
        return (_todayCount * _packPrice) / _packSize;
    }

    function getMonthlyCost() as Number {
        if (_packSize <= 0) { return 0; }
        return (_monthCount * _packPrice) / _packSize;
    }

    function saveSnapshot() as Void {
        var snap = {
            "packLeft"        => _packLeft,
            "todayCount"      => _todayCount,
            "monthCount"      => _monthCount,
            "lastSmokeTime"   => _lastSmokeTime,
            "lastSmokeBaseHr" => _lastSmokeBaseHr,
            "avgIntervalSec"  => _avgIntervalSec,
            "todayExtraBeats" => _todayExtraBeats
        };
        Storage.setValue(KEY_PREV_SNAPSHOT, snap);
    }

    function restoreSnapshot() as Void {
        var snap = Storage.getValue(KEY_PREV_SNAPSHOT) as Dictionary?;
        if (snap == null) { return; }

        var v = snap.get("packLeft") as Number?;
        if (v != null) { _packLeft = v; Storage.setValue(KEY_PACK_LEFT, _packLeft); }

        v = snap.get("todayCount") as Number?;
        if (v != null) { _todayCount = v; Storage.setValue(KEY_TODAY_COUNT, _todayCount); }

        v = snap.get("monthCount") as Number?;
        if (v != null) { _monthCount = v; Storage.setValue(KEY_MONTH_COUNT, _monthCount); }

        v = snap.get("lastSmokeTime") as Number?;
        if (v != null) { _lastSmokeTime = v; Storage.setValue(KEY_LAST_SMOKE_TIME, _lastSmokeTime); }

        v = snap.get("lastSmokeBaseHr") as Number?;
        if (v != null) { _lastSmokeBaseHr = v; Storage.setValue(KEY_LAST_SMOKE_BASEHR, _lastSmokeBaseHr); }

        v = snap.get("avgIntervalSec") as Number?;
        if (v != null) { _avgIntervalSec = v; Storage.setValue(KEY_AVG_INTERVAL_SEC, _avgIntervalSec); }

        v = snap.get("todayExtraBeats") as Number?;
        if (v != null) { _todayExtraBeats = v; Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats); }
    }

    function autoLog(baseHr as Number) as Boolean {
        saveSnapshot();

        var nowSec = Time.now().value().toNumber();
        if (_lastSmokeTime > 0) {
            var interval = nowSec - _lastSmokeTime;
            if (interval >= 300 && interval <= 14400) {
                _avgIntervalSec = ((_avgIntervalSec * 7) + (interval * 3)) / 10;
                Storage.setValue(KEY_AVG_INTERVAL_SEC, _avgIntervalSec);
            }
        }

        var newPack = false;
        if (_packLeft <= 0) {
            _packLeft = _packSize - 1;
            newPack = true;
        } else {
            _packLeft -= 1;
        }

        _todayCount += 1;
        _monthCount += 1;
        _lastSmokeTime = nowSec;
        _lastSmokeBaseHr = baseHr;

        var spike = (_lastHrSpike > 0) ? _lastHrSpike : 12;
        _todayExtraBeats += (spike * 30);

        Storage.setValue(KEY_PACK_LEFT, _packLeft);
        Storage.setValue(KEY_TODAY_COUNT, _todayCount);
        Storage.setValue(KEY_MONTH_COUNT, _monthCount);
        Storage.setValue(KEY_LAST_SMOKE_TIME, _lastSmokeTime);
        Storage.setValue(KEY_LAST_SMOKE_BASEHR, _lastSmokeBaseHr);
        Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats);

        return newPack;
    }

    function manualLog(baseHr as Number) as Void {
        var nowSec = Time.now().value().toNumber();
        if (_lastSmokeTime > 0) {
            var interval = nowSec - _lastSmokeTime;
            if (interval >= 300 && interval <= 14400) {
                _avgIntervalSec = ((_avgIntervalSec * 7) + (interval * 3)) / 10;
                Storage.setValue(KEY_AVG_INTERVAL_SEC, _avgIntervalSec);
            }
        }

        if (_packLeft <= 0) {
            _packLeft = _packSize - 1;
        } else {
            _packLeft -= 1;
        }

        _todayCount += 1;
        _monthCount += 1;
        _lastSmokeTime = nowSec;
        _lastSmokeBaseHr = (baseHr > 30 && baseHr < 240) ? baseHr : 75;

        var spike = (_lastHrSpike > 0) ? _lastHrSpike : 12;
        _todayExtraBeats += (spike * 30);

        Storage.setValue(KEY_PACK_LEFT, _packLeft);
        Storage.setValue(KEY_TODAY_COUNT, _todayCount);
        Storage.setValue(KEY_MONTH_COUNT, _monthCount);
        Storage.setValue(KEY_LAST_SMOKE_TIME, _lastSmokeTime);
        Storage.setValue(KEY_LAST_SMOKE_BASEHR, _lastSmokeBaseHr);
        Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats);
    }

    function openNewPack() as Void {
        _packLeft = _packSize;
        Storage.setValue(KEY_PACK_LEFT, _packLeft);
    }

    function removeOneLog() as Void {
        if (_todayCount > 0) {
            _todayCount -= 1;
            Storage.setValue(KEY_TODAY_COUNT, _todayCount);
        }
        if (_monthCount > 0) {
            _monthCount -= 1;
            Storage.setValue(KEY_MONTH_COUNT, _monthCount);
        }
        if (_packLeft < _packSize) {
            _packLeft += 1;
            Storage.setValue(KEY_PACK_LEFT, _packLeft);
        }
        var spike = (_lastHrSpike > 0) ? _lastHrSpike : 12;
        var reduce = spike * 30;
        if (_todayExtraBeats >= reduce) {
            _todayExtraBeats -= reduce;
        } else {
            _todayExtraBeats = 0;
        }
        Storage.setValue(KEY_TODAY_EXTRA_BEATS, _todayExtraBeats);

        if (_todayCount == 0) {
            _lastSmokeTime = 0;
            Storage.setValue(KEY_LAST_SMOKE_TIME, 0);
        }
    }

    function resetToday() as Void {
        _todayCount = 0;
        _todayExtraBeats = 0;
        _lastSmokeTime = 0;
        Storage.setValue(KEY_TODAY_COUNT, 0);
        Storage.setValue(KEY_TODAY_EXTRA_BEATS, 0);
        Storage.setValue(KEY_LAST_SMOKE_TIME, 0);
    }
}