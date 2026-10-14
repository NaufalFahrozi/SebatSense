import Toybox.Activity;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class SebatView extends WatchUi.View {

    public static const MODE_COUNTDOWN as Number = 0;
    public static const MODE_DASHBOARD as Number = 1;

    public static const PAGE_BIOMETRIC as Number = 0;
    public static const PAGE_IMPACT    as Number = 1;
    public static const PAGE_STOCK     as Number = 2;
    public static const PAGE_MONEY     as Number = 3;
    public static const PAGE_SETTINGS  as Number = 4;
    private static const TOTAL_PAGES   as Number = 5;

    // 3 Titik Vertikal di Zona Aman Tengah Lingkaran (Bebas Potongan Bezel)
    private static const Y_TOP         as Number = 92;
    private static const Y_MID         as Number = 175;
    private static const Y_SUB         as Number = 225;
    private static const Y_BOT         as Number = 285;

    private static const CENTER_HV     as Number = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    private var _dm             as SebatDataManager;
    private var _mode           as Number = 0;
    private var _page           as Number = 0;
    private var _countdownSec   as Number = 3;
    private var _timer          as Timer.Timer?;
    private var _isChainSmoking as Boolean = false;
    private var _newPackOpened  as Boolean = false;
    private var _warningFlash   as Boolean = false;
    private var _heartBeat      as Boolean = false;
    private var _cachedHr       as Number = 75;

    function initialize() {
        View.initialize();
        _dm = new SebatDataManager();
    }

    function onShow() as Void {
        _dm.loadAll();
        _dm.checkRollover();

        if (_mode == MODE_COUNTDOWN) {
            analyzeImpact();
            _isChainSmoking = _dm.isChainSmoking();
            var baseHr = getCurrentHr();
            _newPackOpened = _dm.autoLog(baseHr);
            doHaptics(_isChainSmoking);
            startCountdown();
        } else {
            startDashboardTimer();
        }
    }

    function startCountdown() as Void {
        stopTimer();
        _countdownSec = 3;
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 1000, true);
    }

    function onTick() as Void {
        _countdownSec -= 1;
        _warningFlash = !_warningFlash;
        if (_countdownSec <= 0) {
            stopTimer();
            System.exit();
        } else {
            WatchUi.requestUpdate();
        }
    }

    function startDashboardTimer() as Void {
        stopTimer();
        _timer = new Timer.Timer();
        _timer.start(method(:onDashboardTick), 1000, true);
    }

    function onDashboardTick() as Void {
        _heartBeat = !_heartBeat;
        WatchUi.requestUpdate();
    }

    function stopTimer() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onHide() as Void {
        stopTimer();
    }

    function getMode() as Number                  { return _mode; }
    function getPage() as Number                  { return _page; }
    function getDataManager() as SebatDataManager { return _dm; }

    function undoAndEnterDashboard() as Void {
        stopTimer();
        _dm.restoreSnapshot();
        _mode = MODE_DASHBOARD;
        _page = PAGE_BIOMETRIC;
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(60, 100),
                new Attention.VibeProfile(0, 80),
                new Attention.VibeProfile(60, 100)
            ]);
        }
        startDashboardTimer();
        WatchUi.requestUpdate();
    }

    function nextPage() as Void {
        _page = (_page + 1) % TOTAL_PAGES;
        WatchUi.requestUpdate();
    }

    function previousPage() as Void {
        _page = (_page + TOTAL_PAGES - 1) % TOTAL_PAGES;
        WatchUi.requestUpdate();
    }

    function reloadData() as Void {
        _dm.loadAll();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_mode == MODE_COUNTDOWN) {
            drawCountdown(dc);
        } else {
            drawDashboard(dc);
        }
    }

    // =========================================================================
    // MODE 0: AUTO-LOG 3 DETIK (HANYA 3 ZONA: ATAS - TENGAH - BAWAH)
    // =========================================================================
    private function drawCountdown(dc as Dc) as Void {
        var todayCnt  = _dm.getTodayCount();
        var packLeft  = _dm.getPackLeft();
        var packSize  = _dm.getPackSize();
        var hrSpike   = _dm.getLastHrSpike();
        var dispSpike = (hrSpike > 0) ? hrSpike : 12;

        // Ring Tipis di Pinggir Layar
        dc.setPenWidth(5);
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(195, 195, 190);

        var arcDeg = _countdownSec * 120;
        var arcColor = _isChainSmoking ? (_warningFlash ? 0xFF1744 : 0xFF9800) : 0xFF9800;
        dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);
        if (arcDeg >= 360) {
            dc.drawCircle(195, 195, 190);
        } else if (arcDeg > 0) {
            dc.drawArc(195, 195, 190, Graphics.ARC_CLOCKWISE, 90, (90 - arcDeg + 360) % 360);
        }
        dc.setPenWidth(1);

        // ATAS (y = 92, Font Kecil)
        if (_isChainSmoking) {
            dc.setColor(0xFF1744, Graphics.COLOR_TRANSPARENT);
            dc.drawText(195, Y_TOP, Graphics.FONT_GLANCE, "CHAIN SMOKING!", CENTER_HV);
        } else if (_newPackOpened) {
            dc.setColor(0x00E676, Graphics.COLOR_TRANSPARENT);
            dc.drawText(195, Y_TOP, Graphics.FONT_GLANCE, "BUNGKUS BARU", CENTER_HV);
        } else {
            dc.setColor(0xFF9800, Graphics.COLOR_TRANSPARENT);
            dc.drawText(195, Y_TOP, Graphics.FONT_GLANCE, "TERCATAT", CENTER_HV);
        }

        // TENGAH (y = 175 & y = 225)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_MID, Graphics.FONT_MEDIUM, Lang.format("Batang #$1$", [todayCnt]), CENTER_HV);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_SUB, Graphics.FONT_GLANCE, Lang.format("Sisa $1$/$2$  •  HR +$3$", [packLeft, packSize, dispSpike]), CENTER_HV);

        // BAWAH (y = 285, Tombol Pill Hijau dengan outline)
        dc.setColor(0x0a2612, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(95, Y_BOT - 16, 200, 32, 16);
        dc.setColor(0x1b5e20, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(95, Y_BOT - 16, 200, 32, 16);
        dc.setColor(0x00E676, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_BOT, Graphics.FONT_GLANCE, Lang.format("Tap: Batal ($1$s)", [_countdownSec]), CENTER_HV);
    }

    // =========================================================================
    // MODE 1: DASHBOARD 5 HALAMAN (MINIMALIS)
    // =========================================================================
    private function drawDashboard(dc as Dc) as Void {
        drawBezelGauge(dc);
        if (_page == PAGE_BIOMETRIC) {
            drawBiometricPage(dc);
        } else if (_page == PAGE_IMPACT) {
            drawImpactPage(dc);
        } else if (_page == PAGE_STOCK) {
            drawStockPage(dc);
        } else if (_page == PAGE_MONEY) {
            drawMoneyPage(dc);
        } else {
            drawSettingsPage(dc);
        }
        drawPageDots(dc);
    }

    private function drawBezelGauge(dc as Dc) as Void {
        dc.setPenWidth(3);
        dc.setColor(0x1F1F1F, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(195, 195, 191);

        if (_page == PAGE_BIOMETRIC) {
            var elapsed = _dm.getSecondsSinceLastSmoke();
            var phase = _dm.getRecoveryPhase();
            var phaseClr = (phase == 0) ? 0xFF3D3D : ((phase == 1) ? 0xFF9800 : 0x00E676);
            if (elapsed < 0 || elapsed >= 7200) {
                dc.setColor(0x00E676, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(195, 195, 191);
            } else {
                var recProg = elapsed.toFloat() / 7200.0f;
                if (recProg < 0.03f) { recProg = 0.03f; }
                var deg = (recProg * 360.0f).toNumber();
                dc.setColor(phaseClr, Graphics.COLOR_TRANSPARENT);
                dc.drawArc(195, 195, 191, Graphics.ARC_CLOCKWISE, 90, (90 - deg + 360) % 360);
            }
        } else if (_page == PAGE_STOCK) {
            var packLeft = _dm.getPackLeft();
            var packSize = _dm.getPackSize();
            if (packSize > 0) {
                var stockProg = packLeft.toFloat() / packSize.toFloat();
                if (stockProg > 1.0f) { stockProg = 1.0f; }
                var stockClr = (stockProg > 0.5f) ? 0x00E676 : ((stockProg > 0.2f) ? 0xFF9800 : 0xFF1744);
                if (stockProg >= 1.0f) {
                    dc.setColor(stockClr, Graphics.COLOR_TRANSPARENT);
                    dc.drawCircle(195, 195, 191);
                } else if (stockProg > 0.02f) {
                    var deg = (stockProg * 360.0f).toNumber();
                    dc.setColor(stockClr, Graphics.COLOR_TRANSPARENT);
                    dc.drawArc(195, 195, 191, Graphics.ARC_CLOCKWISE, 90, (90 - deg + 360) % 360);
                }
            }
        } else if (_page == PAGE_IMPACT || _page == PAGE_MONEY) {
            var todayCnt = _dm.getTodayCount();
            if (todayCnt == 0) {
                dc.setColor(0x00E676, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(195, 195, 191);
            }
        }
        dc.setPenWidth(1);
    }

    private function drawPageDots(dc as Dc) as Void {
        var dotX = 370;
        var dotsY = [163, 179, 195, 211, 227];
        for (var i = 0; i < TOTAL_PAGES; i++) {
            if (i == _page) {
                dc.setColor(0xFF9800, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotsY[i], 4);
            } else {
                dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotsY[i], 2);
            }
        }
    }

    // --- HALAMAN 1: STATUS TUBUH ---
    private function drawBiometricPage(dc as Dc) as Void {
        var phase   = _dm.getRecoveryPhase();
        var elapsed = _dm.getSecondsSinceLastSmoke();
        var liveHr  = getCurrentHr();

        var phaseClr = 0x00E676;
        var phaseTxt = "O2 & HR Pulih";
        if (elapsed < 0) {
            phaseClr = 0x00E676;
            phaseTxt = "Paru Aman";
        } else if (phase == 0) {
            phaseClr = 0xFF3D3D;
            phaseTxt = "HR & Tensi Naik";
        } else if (phase == 1) {
            phaseClr = 0xFF9800;
            phaseTxt = "CO Darah Tinggi";
        }

        // ATAS
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_TOP, Graphics.FONT_GLANCE, "STATUS TUBUH", CENTER_HV);

        // TENGAH (Live HR + Pulsing Heart Dot)
        var hrStr = Lang.format("$1$ bpm", [liveHr]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_MID, Graphics.FONT_MEDIUM, hrStr, CENTER_HV);

        var tw = dc.getTextWidthInPixels(hrStr, Graphics.FONT_MEDIUM);
        var dotPulseX = 195 - (tw / 2) - 12;
        var dotR = _heartBeat ? 4 : 3;
        dc.setColor(_heartBeat ? 0xFF1744 : 0xB71C1C, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(dotPulseX, Y_MID, dotR);

        dc.setColor(phaseClr, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_SUB, Graphics.FONT_GLANCE, phaseTxt, CENTER_HV);

        // BAWAH
        var timerTxt = "Kondisi normal";
        if (elapsed >= 0 && elapsed < 1200) {
            timerTxt = Lang.format("Pulih dlm $1$ mnt", [(1200 - elapsed + 59) / 60]);
        } else if (elapsed >= 1200 && elapsed < 7200) {
            timerTxt = Lang.format("CO bersih $1$ mnt", [(7200 - elapsed + 59) / 60]);
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_BOT, Graphics.FONT_GLANCE, timerTxt, CENTER_HV);
    }

    // --- HALAMAN 2: DAMPAK ROKOK ---
    private function drawImpactPage(dc as Dc) as Void {
        var todayCnt   = _dm.getTodayCount();
        var hrSpike    = _dm.getLastHrSpike();
        var peakStress = _dm.getLastPeakStress();
        var extraBeats = _dm.getTodayExtraBeats();

        // ATAS
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_TOP, Graphics.FONT_GLANCE, "DAMPAK ROKOK", CENTER_HV);

        // TENGAH
        if (todayCnt > 0) {
            var dispSpike  = (hrSpike > 0) ? hrSpike : 12;
            var dispStress = (peakStress > 0) ? peakStress : 38;

            dc.setColor(0xFF3D3D, Graphics.COLOR_TRANSPARENT);
            dc.drawText(195, Y_MID, Graphics.FONT_MEDIUM, Lang.format("+$1$ bpm", [dispSpike]), CENTER_HV);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(195, Y_SUB, Graphics.FONT_GLANCE, Lang.format("Stres $1$/100  •  +$2$ detak", [dispStress, extraBeats]), CENTER_HV);

            // BAWAH
            dc.setColor(0xFF9800, Graphics.COLOR_TRANSPARENT);
            dc.drawText(195, Y_BOT, Graphics.FONT_GLANCE, Lang.format("Kardio hilang: -$1$m", [todayCnt * 7]), CENTER_HV);
        } else {
            dc.setColor(0x00E676, Graphics.COLOR_TRANSPARENT);
            dc.drawText(195, Y_MID, Graphics.FONT_MEDIUM, "0 bpm (Aman)", CENTER_HV);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(195, Y_SUB, Graphics.FONT_GLANCE, "Stres Normal  •  0 detak", CENTER_HV);

            // BAWAH
            dc.setColor(0x00E676, Graphics.COLOR_TRANSPARENT);
            dc.drawText(195, Y_BOT, Graphics.FONT_GLANCE, "Jantung & Paru Bersih", CENTER_HV);
        }
    }

    // --- HALAMAN 3: SISA BUNGKUS ---
    private function drawStockPage(dc as Dc) as Void {
        var packLeft = _dm.getPackLeft();
        var packSize = _dm.getPackSize();
        var runOut   = _dm.getPredictedRunOutTime();

        // ATAS
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_TOP, Graphics.FONT_GLANCE, "SISA BUNGKUS", CENTER_HV);

        // TENGAH
        var numClr = Graphics.COLOR_WHITE;
        if (packLeft <= 0) {
            numClr = 0xFF1744;
        } else if (packLeft <= 2) {
            numClr = 0xFF9800;
        }
        dc.setColor(numClr, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_MID, Graphics.FONT_MEDIUM, Lang.format("$1$ / $2$", [packLeft, packSize]), CENTER_HV);

        dc.setColor(0xFFD54F, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_SUB, Graphics.FONT_GLANCE, Lang.format("Prediksi habis: $1$", [runOut]), CENTER_HV);

        // BAWAH (Tombol Pill Biru dengan Border)
        dc.setColor(0x0A2540, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(95, Y_BOT - 16, 200, 32, 16);
        dc.setColor(0x1565C0, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(95, Y_BOT - 16, 200, 32, 16);
        dc.setColor(0x64B5F6, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_BOT, Graphics.FONT_GLANCE, "START: Menu Stok", CENTER_HV);
    }

    // --- HALAMAN 4: UANG TERBAKAR ---
    private function drawMoneyPage(dc as Dc) as Void {
        var todayCnt  = _dm.getTodayCount();
        var todayCost = _dm.formatRupiah(_dm.getTodayCost());
        var monCost   = _dm.formatRupiah(_dm.getMonthlyCost());

        // ATAS
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_TOP, Graphics.FONT_GLANCE, "UANG TERBAKAR", CENTER_HV);

        // TENGAH
        var costClr = (todayCnt > 0) ? 0xFFD54F : 0x00E676;
        dc.setColor(costClr, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_MID, Graphics.FONT_MEDIUM, todayCost, CENTER_HV);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_SUB, Graphics.FONT_GLANCE, Lang.format("Hari ini: $1$ batang", [todayCnt]), CENTER_HV);

        // BAWAH
        dc.setColor(0xFF9800, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_BOT, Graphics.FONT_GLANCE, Lang.format("Bulan ini: $1$", [monCost]), CENTER_HV);
    }

    // --- HALAMAN 5: PENGATURAN ---
    private function drawSettingsPage(dc as Dc) as Void {
        var packSize    = _dm.getPackSize();
        var packPrice   = _dm.getPackPrice();
        var pricePerCig = (packSize > 0) ? (packPrice / packSize) : 0;

        // ATAS
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_TOP, Graphics.FONT_GLANCE, "PENGATURAN", CENTER_HV);

        // TENGAH
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_MID, Graphics.FONT_MEDIUM, _dm.formatRupiah(packPrice), CENTER_HV);

        dc.setColor(0xFFD54F, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_SUB, Graphics.FONT_GLANCE, Lang.format("Isi $1$  •  $2$/btg", [packSize, _dm.formatRupiah(pricePerCig)]), CENTER_HV);

        // BAWAH (Tombol Pill Biru dengan Border)
        dc.setColor(0x0A2540, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(95, Y_BOT - 16, 200, 32, 16);
        dc.setColor(0x1565C0, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(95, Y_BOT - 16, 200, 32, 16);
        dc.setColor(0x64B5F6, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, Y_BOT, Graphics.FONT_GLANCE, "START: Ubah Data", CENTER_HV);
    }

    // =========================================================================
    // SENSOR & BIOMETRIC HELPERS
    // =========================================================================
    function getCurrentHr() as Number {
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo.currentHeartRate != null) {
            var rawHr = actInfo.currentHeartRate as Number;
            if (rawHr > 30 && rawHr < 240) {
                _cachedHr = rawHr;
                return rawHr;
            }
        }
        if ((Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory)) {
            var iter = SensorHistory.getHeartRateHistory({
                :period => new Time.Duration(600),
                :order  => SensorHistory.ORDER_NEWEST_FIRST
            });
            if (iter != null) {
                var s = iter.next();
                if (s != null && s.data != null) {
                    var d = (s.data as Numeric).toNumber();
                    if (d > 30 && d < 240) {
                        _cachedHr = d;
                        return d;
                    }
                }
            }
        }
        return _cachedHr;
    }

    function analyzeImpact() as Void {
        var lastTime = _dm.getLastSmokeTime();
        if (lastTime <= 0) { return; }

        var nowSec = Time.now().value().toNumber();
        var elapsed = nowSec - lastTime;
        if (elapsed < 300 || elapsed > 21600) { return; }

        var baseHr   = _dm.getLastSmokeBaseHr();
        var winStart = lastTime;
        var winEnd   = lastTime + 1500;

        var maxHr     = baseHr;
        var maxStress = 0;

        var queryPeriod = elapsed + 300;
        if (queryPeriod > 21600) { queryPeriod = 21600; }

        if ((Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory)) {
            var hrIter = SensorHistory.getHeartRateHistory({
                :period => new Time.Duration(queryPeriod),
                :order  => SensorHistory.ORDER_NEWEST_FIRST
            });
            if (hrIter != null) {
                var samp = hrIter.next();
                while (samp != null) {
                    if (samp.when != null && samp.data != null) {
                        var t = samp.when.value().toNumber();
                        if (t < winStart) {
                            break;
                        }
                        var bpm = (samp.data as Numeric).toNumber();
                        if (t <= winEnd && bpm > maxHr && bpm < 240) {
                            maxHr = bpm;
                        }
                    }
                    samp = hrIter.next();
                }
            }
        }

        if ((Toybox has :SensorHistory) && (SensorHistory has :getStressHistory)) {
            var stIter = SensorHistory.getStressHistory({
                :period => new Time.Duration(queryPeriod),
                :order  => SensorHistory.ORDER_NEWEST_FIRST
            });
            if (stIter != null) {
                var samp = stIter.next();
                while (samp != null) {
                    if (samp.when != null && samp.data != null) {
                        var t = samp.when.value().toNumber();
                        if (t < winStart) {
                            break;
                        }
                        var stv = (samp.data as Numeric).toNumber();
                        if (t <= winEnd && stv > maxStress && stv <= 100) {
                            maxStress = stv;
                        }
                    }
                    samp = stIter.next();
                }
            }
        }

        var spike = maxHr - baseHr;
        if (spike <= 0) { spike = 12; }
        if (maxStress <= 0) { maxStress = 38; }

        _dm.setLastHrSpike(spike);
        _dm.setLastPeakStress(maxStress);
    }

    private function doHaptics(chain as Boolean) as Void {
        if (!(Attention has :vibrate)) { return; }
        if (chain) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 250),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(100, 250),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(100, 350)
            ]);
        } else {
            Attention.vibrate([new Attention.VibeProfile(80, 180)]);
        }
    }
}