import Toybox.Activity;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// ─────────────────────────────────────────────────────────────────────────────
// SebatView – 390×390 round AMOLED (fr165)
//
// MODE_COUNTDOWN  : 3-second auto-exit screen (bezel arc + biometric card)
// MODE_DASHBOARD  : 3-page interactive dashboard (entered on tap/undo)
// ─────────────────────────────────────────────────────────────────────────────
class SebatView extends WatchUi.View {

    // ── Constants ──────────────────────────────────────────────────────────────
    static const MODE_COUNTDOWN  as Number = 0;
    static const MODE_DASHBOARD  as Number = 1;
    static const PAGE_BIOMETRIC  as Number = 0;
    static const PAGE_STOCK      as Number = 1;
    static const PAGE_SETTINGS   as Number = 2;

    // Screen geometry
    private static const CX  as Number = 195;
    private static const CY  as Number = 195;
    private static const ARC_R as Number = 186; // bezel arc radius
    // Card safe zone inside 390×390 circle
    private static const CARD_X as Number = 50;
    private static const CARD_W as Number = 290;

    // ── State ──────────────────────────────────────────────────────────────────
    private var _dm             as SebatDataManager;
    private var _mode           as Number  = MODE_COUNTDOWN;
    private var _page           as Number  = PAGE_BIOMETRIC;
    private var _countdownSec   as Number  = 3;
    private var _timer          as Timer.Timer?;
    private var _warningFlash   as Boolean = false;
    private var _newPackOpened  as Boolean = false;
    private var _isChainSmoking as Boolean = false;

    // ── Constructor ────────────────────────────────────────────────────────────
    function initialize() {
        View.initialize();
        _dm = new SebatDataManager();
    }

    // ── onShow : orchestrate auto-log sequence ─────────────────────────────────
    function onShow() as Void {
        _dm.loadAll();

        // 1. Midnight rollover
        _dm.checkRollover();

        // 2. Chain-smoking flag (checked BEFORE logging)
        _isChainSmoking = _dm.isChainSmoking();

        // 3. Retrospective biometric analysis of PREVIOUS smoke
        analyzeImpact();

        // 4. Auto-log (snapshot saved internally for undo)
        var baseHr      = getCurrentHr();
        _newPackOpened  = _dm.autoLog(baseHr);

        // 5. Haptic feedback
        doHaptics(_isChainSmoking);

        // 6. Start countdown
        _mode         = MODE_COUNTDOWN;
        _countdownSec = 3;
        startCountdown();
    }

    // ── Countdown Timer ────────────────────────────────────────────────────────
    function startCountdown() as Void {
        _timer = new Timer.Timer();
        (_timer as Timer.Timer).start(method(:onTick), 1000, true);
    }

    function onTick() as Void {
        _countdownSec  = _countdownSec - 1;
        _warningFlash  = !_warningFlash;
        WatchUi.requestUpdate();
        if (_countdownSec <= 0) {
            stopTimer();
            System.exit();
        }
    }

    function stopTimer() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    // ── Public API (called by SebatDelegate) ───────────────────────────────────
    function getMode()    as Number { return _mode; }
    function getPage()    as Number { return _page; }
    function getDataManager() as SebatDataManager { return _dm; }

    function undoAndEnterDashboard() as Void {
        stopTimer();
        _dm.restoreSnapshot();
        _newPackOpened  = false;
        _isChainSmoking = false;
        doHaptics(false); // double vibration for undo
        _mode = MODE_DASHBOARD;
        _page = PAGE_BIOMETRIC;
        WatchUi.requestUpdate();
    }

    function nextPage() as Void {
        if (_page < PAGE_SETTINGS) { _page = _page + 1; WatchUi.requestUpdate(); }
    }

    function previousPage() as Void {
        if (_page > PAGE_BIOMETRIC) { _page = _page - 1; WatchUi.requestUpdate(); }
    }

    function reloadData() as Void {
        _dm.loadAll();
        WatchUi.requestUpdate();
    }

    // ── Main Draw Dispatch ─────────────────────────────────────────────────────
    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (_mode == MODE_COUNTDOWN) {
            drawCountdown(dc);
        } else {
            drawDashboard(dc);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // COUNTDOWN SCREEN
    // ══════════════════════════════════════════════════════════════════════════
    private function drawCountdown(dc as Graphics.Dc) as Void {

        // ── Chain-smoking red tint ────────────────────────────────────────────
        if (_isChainSmoking && _warningFlash) {
            dc.setColor(0x2B0000, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(CX, CY, CY);
        }

        // ── Bezel arc track (full circle, dark gray) ──────────────────────────
        dc.setPenWidth(8);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(CX, CY, ARC_R, Graphics.ARC_CLOCKWISE, 90, -270);

        // ── Bezel arc progress ────────────────────────────────────────────────
        // 3s→360°  2s→240°  1s→120°
        var arcDeg   = _countdownSec * 120;
        var arcColor = _isChainSmoking ? Graphics.COLOR_RED : Graphics.COLOR_ORANGE;
        if (arcDeg > 0) {
            dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(CX, CY, ARC_R, Graphics.ARC_CLOCKWISE, 90, 90 - arcDeg);
        }
        dc.setPenWidth(1);

        // ── Banner (top) ──────────────────────────────────────────────────────
        var bannerY = 36;
        if (_newPackOpened) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(CX, bannerY, Graphics.FONT_TINY, "BUNGKUS BARU DIBUKA!", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (_isChainSmoking) {
            dc.setColor(_warningFlash ? Graphics.COLOR_RED : 0x880000, Graphics.COLOR_TRANSPARENT);
            dc.drawText(CX, bannerY, Graphics.FONT_TINY, "! CHAIN SMOKING !", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(CX, bannerY, Graphics.FONT_TINY, "SebatSense  dicatat", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // ── Countdown number ──────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 58, Graphics.FONT_NUMBER_HOT, _countdownSec.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        // ── TAMPARAN REALITA card  (y=138 → y=285) ────────────────────────────
        var cY  = 138;
        var cH  = 147;
        dc.setColor(0x1C0000, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(CARD_X, cY, CARD_W, cH, 10);
        dc.setPenWidth(2);
        dc.setColor(0x880000, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(CARD_X, cY, CARD_W, cH, 10);
        dc.setPenWidth(1);

        // Card title
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, cY + 6, Graphics.FONT_XTINY, "TAMPARAN REALITA (Batang Sebelumnya)", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x550000, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(CARD_X + 8, cY + 22, CARD_X + CARD_W - 8, cY + 22);

        var hrSpike    = _dm.getLastHrSpike();
        var peakStress = _dm.getLastPeakStress();
        var extraBeats = _dm.getTodayExtraBeats();
        var baseHrVal  = _dm.getLastSmokeBaseHr();
        var peakHr     = baseHrVal + hrSpike;
        var todayCost  = _dm.getTodayCost();
        var todayCnt   = _dm.getTodayCount();
        var packLeft   = _dm.getPackLeft();
        var packSize   = _dm.getPackSize();

        var rowY = cY + 27;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("HR: $1$  $2$ bpm (+$3$)", [baseHrVal, peakHr, hrSpike]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 20;
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Peak Stress: $1$ / 100", [peakStress]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 20;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Ekstra Detak Hari ini: +$1$", [extraBeats]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 20;
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Uang Terbakar: $1$", [_dm.formatRupiah(todayCost)]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 20;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Hari ini: $1$ btg  |  Sisa: $2$/$3$ btg", [todayCnt, packLeft, packSize]),
            Graphics.TEXT_JUSTIFY_LEFT);

        // ── Bottom instruction ────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 297, Graphics.FONT_XTINY,
            "Tap layar / START = BATAL & Menu",
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // DASHBOARD
    // ══════════════════════════════════════════════════════════════════════════
    private function drawDashboard(dc as Graphics.Dc) as Void {
        if (_page == PAGE_BIOMETRIC) {
            drawBiometricPage(dc);
        } else if (_page == PAGE_STOCK) {
            drawStockPage(dc);
        } else {
            drawSettingsPage(dc);
        }
        drawPageDots(dc);
    }

    // ── Page Indicator Dots ───────────────────────────────────────────────────
    private function drawPageDots(dc as Graphics.Dc) as Void {
        var dotX  = 372;
        var dotsY = [180, 195, 210] as Array<Number>;
        for (var i = 0; i < 3; i++) {
            if (i == _page) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotsY[i], 5);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotsY[i], 3);
            }
        }
    }

    // ── Page 1: Biometric ─────────────────────────────────────────────────────
    private function drawBiometricPage(dc as Graphics.Dc) as Void {
        // Title
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 36, Graphics.FONT_TINY, "Tamparan Biometrik", Graphics.TEXT_JUSTIFY_CENTER);

        // Recovery arc on bezel
        var phase    = _dm.getRecoveryPhase();
        var phaseClr = Graphics.COLOR_RED;
        var phaseTxt = "HR/Tensi Naik";
        var elapsed  = _dm.getSecondsSinceLastSmoke();

        if (phase == 1) { phaseClr = Graphics.COLOR_ORANGE; phaseTxt = "CO Darah Tinggi"; }
        else if (phase == 2) { phaseClr = Graphics.COLOR_GREEN; phaseTxt = "O2 & HR Pulih"; }

        var arcFrac = 0.0f;
        if (phase == 0 && elapsed > 0) {
            arcFrac = elapsed.toFloat() / 1200.0f;
        } else if (phase == 1) {
            arcFrac = (elapsed - 1200).toFloat() / 6000.0f;
        } else if (phase == 2) {
            arcFrac = 1.0f;
        }
        if (arcFrac > 1.0f) { arcFrac = 1.0f; }
        var arcDeg = (arcFrac * 360.0f).toNumber();

        dc.setPenWidth(8);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(CX, CY, ARC_R, Graphics.ARC_CLOCKWISE, 90, -270);
        if (arcDeg > 0) {
            dc.setColor(phaseClr, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(CX, CY, ARC_R, Graphics.ARC_CLOCKWISE, 90, 90 - arcDeg);
        }
        dc.setPenWidth(1);

        // Live HR
        var hrDisplay = "--";
        var actInfo   = Activity.getActivityInfo();
        if (actInfo != null) {
            var liveHr = actInfo.currentHeartRate;
            if (liveHr != null && liveHr > 0) {
                hrDisplay = liveHr.toString();
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 60, Graphics.FONT_NUMBER_MEDIUM, hrDisplay, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 102, Graphics.FONT_XTINY, "bpm (live)", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(phaseClr, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 118, Graphics.FONT_XTINY, phaseTxt, Graphics.TEXT_JUSTIFY_CENTER);

        // Biometric card (y=136 → y=286)
        var cY = 136;
        var cH = 150;
        dc.setColor(0x0D0D20, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(CARD_X, cY, CARD_W, cH, 8);
        dc.setColor(0x222255, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(CARD_X, cY, CARD_W, cH, 8);

        var hrSpike    = _dm.getLastHrSpike();
        var peakStress = _dm.getLastPeakStress();
        var extraBeats = _dm.getTodayExtraBeats();
        var baseHrVal  = _dm.getLastSmokeBaseHr();
        var todayCnt   = _dm.getTodayCount();
        var peakHr     = baseHrVal + hrSpike;
        var cardioMin  = (hrSpike * todayCnt) / 5;

        var rowY = cY + 8;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("HR: $1$ -> $2$ bpm (+$3$)", [baseHrVal, peakHr, hrSpike]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 22;
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Peak Stress: $1$ / 100", [peakStress]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 22;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Ekstra Detak: +$1$ detak", [extraBeats]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 22;
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Batang hari ini: $1$ btg", [todayCnt]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 22;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Est. Waktu Kardio: -$1$ mnt", [cardioMin]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 22;
        var normTxt = "HR sudah pulih";
        if (elapsed < 1200) {
            var remMin = (1200 - elapsed) / 60;
            normTxt = Lang.format("HR pulih: $1$ mnt lagi", [remMin]);
        }
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY, normTxt, Graphics.TEXT_JUSTIFY_LEFT);

        // Bottom hint
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 301, Graphics.FONT_XTINY, "Swipe atas/bawah ganti hal.", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ── Page 2: Stock & Financial ─────────────────────────────────────────────
    private function drawStockPage(dc as Graphics.Dc) as Void {
        // Title
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 36, Graphics.FONT_TINY, "Stok & Finansial", Graphics.TEXT_JUSTIFY_CENTER);

        var packLeft  = _dm.getPackLeft();
        var packSize  = _dm.getPackSize();
        var packPrice = _dm.getPackPrice();
        var avgSec    = _dm.getAvgIntervalSec();
        var runOut    = _dm.getPredictedRunOutTime();
        var todayCost = _dm.getTodayCost();
        var monCost   = _dm.getMonthlyCost();
        var todayCnt  = _dm.getTodayCount();

        var avgH = avgSec / 3600;
        var avgM = (avgSec % 3600) / 60;

        // Pack progress bar
        var barX = 55;
        var barW = 280;
        var barH = 22;
        var barY = 62;
        dc.setColor(0x303030, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barX, barY, barW, barH, 5);
        if (packSize > 0 && packLeft > 0) {
            var fillW = (barW * packLeft / packSize).toNumber();
            var bClr  = Graphics.COLOR_GREEN;
            if (packLeft <= 3)      { bClr = Graphics.COLOR_RED; }
            else if (packLeft <= 6) { bClr = Graphics.COLOR_ORANGE; }
            dc.setColor(bClr, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, barY, fillW, barH, 5);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, barY + 4, Graphics.FONT_XTINY,
            Lang.format("Sisa: $1$ / $2$ btg", [packLeft, packSize]),
            Graphics.TEXT_JUSTIFY_CENTER);

        // Detail card (y=94 → y=286)
        var cY = 94;
        var cH = 192;
        dc.setColor(0x0D200D, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(CARD_X, cY, CARD_W, cH, 8);
        dc.setColor(0x224422, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(CARD_X, cY, CARD_W, cH, 8);

        var rowY = cY + 8;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Batang hari ini: $1$ btg", [todayCnt]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 22;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (avgH > 0) {
            dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
                Lang.format("Rata jeda: $1$j $2$m", [avgH, avgM]),
                Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
                Lang.format("Rata jeda: $1$ mnt", [avgM]),
                Graphics.TEXT_JUSTIFY_LEFT);
        }

        rowY += 22;
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Prediksi habis: $1$", [runOut]),
            Graphics.TEXT_JUSTIFY_LEFT);

        // Separator
        dc.setColor(0x224422, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(CARD_X + 8, cY + 80, CARD_X + CARD_W - 8, cY + 80);

        rowY = cY + 88;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY, "FINANSIAL:", Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 20;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Hari ini:    $1$", [_dm.formatRupiah(todayCost)]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 20;
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Bulan ini:   $1$", [_dm.formatRupiah(monCost)]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 20;
        var pricePerCig = (packSize > 0) ? (packPrice / packSize) : 0;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY,
            Lang.format("Per batang:  $1$", [_dm.formatRupiah(pricePerCig)]),
            Graphics.TEXT_JUSTIFY_LEFT);

        rowY += 22;
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, rowY, Graphics.FONT_XTINY, "Tekan START untuk Menu Aksi", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 301, Graphics.FONT_XTINY, "Swipe atas/bawah ganti hal.", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ── Page 3: Settings ──────────────────────────────────────────────────────
    private function drawSettingsPage(dc as Graphics.Dc) as Void {
        // Title
        dc.setColor(0x5588FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 36, Graphics.FONT_TINY, "Pengaturan Rokok", Graphics.TEXT_JUSTIFY_CENTER);

        var packSize  = _dm.getPackSize();
        var packPrice = _dm.getPackPrice();
        var pricePerCig = (packSize > 0) ? (packPrice / packSize) : 0;

        // Settings card (y=62 → y=280)
        var cY = 62;
        var cH = 218;
        dc.setColor(0x0D0D20, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(CARD_X, cY, CARD_W, cH, 8);
        dc.setColor(0x222266, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(CARD_X, cY, CARD_W, cH, 8);

        var rX  = CARD_X + CARD_W - 8;
        var rowY = cY + 12;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY, "Isi per Bungkus:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rX, rowY, Graphics.FONT_XTINY,
            Lang.format("$1$ batang", [packSize]),
            Graphics.TEXT_JUSTIFY_RIGHT);

        rowY += 30;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY, "Harga per Bungkus:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rX, rowY, Graphics.FONT_XTINY,
            _dm.formatRupiah(packPrice),
            Graphics.TEXT_JUSTIFY_RIGHT);

        rowY += 30;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY, "Harga per Batang:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rX, rowY, Graphics.FONT_XTINY,
            _dm.formatRupiah(pricePerCig),
            Graphics.TEXT_JUSTIFY_RIGHT);

        // Separator
        dc.setColor(0x222266, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(CARD_X + 8, cY + 106, CARD_X + CARD_W - 8, cY + 106);

        rowY = cY + 114;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY, "Versi:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rX, rowY, Graphics.FONT_XTINY, "1.0.0", Graphics.TEXT_JUSTIFY_RIGHT);

        rowY += 28;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CARD_X + 8, rowY, Graphics.FONT_XTINY, "Perangkat:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rX, rowY, Graphics.FONT_XTINY, "Forerunner 165", Graphics.TEXT_JUSTIFY_RIGHT);

        rowY += 38;
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, rowY, Graphics.FONT_XTINY, "Tekan START untuk ubah", Graphics.TEXT_JUSTIFY_CENTER);
        rowY += 18;
        dc.drawText(CX, rowY, Graphics.FONT_XTINY, "pengaturan atau Reset data", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawText(CX, 301, Graphics.FONT_XTINY, "Swipe atas/bawah ganti hal.", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // HELPER: Get Current HR (Activity → SensorHistory fallback → 75)
    // ══════════════════════════════════════════════════════════════════════════
    function getCurrentHr() as Number {
        var hr = 75;
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null) {
            var rawHr = actInfo.currentHeartRate;
            if (rawHr != null && rawHr > 0) { return rawHr; }
        }
        if ((Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory)) {
            var iter = SensorHistory.getHeartRateHistory({
                :period => new Time.Duration(300),
                :order  => SensorHistory.ORDER_NEWEST_FIRST
            });
            if (iter != null) {
                var s = iter.next();
                if (s != null && s.data != null) {
                    var d = s.data as Number;
                    if (d > 0) { hr = d; }
                }
            }
        }
        return hr;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // HELPER: Retrospective SensorHistory Analysis of PREVIOUS smoke
    // Sets _dm.lastHrSpike and _dm.lastPeakStress
    // ══════════════════════════════════════════════════════════════════════════
    function analyzeImpact() as Void {
        var lastTime = _dm.getLastSmokeTime();
        if (lastTime == 0) { return; }

        var nowSec  = Time.now().value().toNumber();
        var elapsed = nowSec - lastTime;
        if (elapsed < 300 || elapsed > 21600) { return; }

        var baseHr    = _dm.getLastSmokeBaseHr();
        var winStart  = lastTime;
        var winEnd    = lastTime + 1500; // 25-minute window

        var maxHr     = baseHr;
        var maxStress = 0;

        if (!((Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory))) {
            // Simulator fallback
            _dm.setLastHrSpike((_dm.getLastHrSpike() > 0) ? _dm.getLastHrSpike() : 12);
            _dm.setLastPeakStress((_dm.getLastPeakStress() > 0) ? _dm.getLastPeakStress() : 35);
            return;
        }

        // HR analysis
        var hrIter = SensorHistory.getHeartRateHistory({
            :period => new Time.Duration(21600),
            :order  => SensorHistory.ORDER_OLDEST_FIRST
        });
        if (hrIter != null) {
            var samp = hrIter.next();
            while (samp != null) {
                var when = samp.when;
                var data = samp.data;
                if (when != null && data != null) {
                    var t  = when.value().toNumber();
                    var bpm = data as Number;
                    if (t >= winStart && t <= winEnd && bpm > maxHr) {
                        maxHr = bpm;
                    }
                }
                samp = hrIter.next();
            }
        }

        // Stress analysis
        if (SensorHistory has :getStressHistory) {
            var stIter = SensorHistory.getStressHistory({
                :period => new Time.Duration(21600),
                :order  => SensorHistory.ORDER_OLDEST_FIRST
            });
            if (stIter != null) {
                var samp = stIter.next();
                while (samp != null) {
                    var when = samp.when;
                    var data = samp.data;
                    if (when != null && data != null) {
                        var t   = when.value().toNumber();
                        var stv = data as Number;
                        if (t >= winStart && t <= winEnd && stv > maxStress) {
                            maxStress = stv;
                        }
                    }
                    samp = stIter.next();
                }
            }
        }

        var spike = maxHr - baseHr;
        if (spike < 0) { spike = 0; }
        if (spike == 0) { spike = 12; } // realistic minimum fallback

        _dm.setLastHrSpike(spike);
        _dm.setLastPeakStress((maxStress > 0) ? maxStress : 35);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // HELPER: Haptic feedback
    // ══════════════════════════════════════════════════════════════════════════
    private function doHaptics(chain as Boolean) as Void {
        if (!(Attention has :vibrate)) { return; }
        if (chain) {
            // Triple heavy (chain-smoking warning)
            Attention.vibrate([
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0,   100),
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0,   100),
                new Attention.VibeProfile(100, 200)
            ] as Array<Attention.VibeProfile>);
        } else {
            // Single crisp confirmation (also used for undo double-buzz via two calls)
            Attention.vibrate([
                new Attention.VibeProfile(70, 120),
                new Attention.VibeProfile(0,  80),
                new Attention.VibeProfile(70, 120)
            ] as Array<Attention.VibeProfile>);
        }
    }
}
