import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

(:glance)
class SebatGlanceView extends WatchUi.GlanceView {
    private var _dm as SebatDataManager;

    function initialize() {
        GlanceView.initialize();
        _dm = new SebatDataManager();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        _dm.loadAll();
        _dm.checkRollover();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var barW = w - 45;
        if (barW < 90) { barW = w - 15; }

        var packLeft = _dm.getPackLeft();
        var packSize = _dm.getPackSize();
        var todayCnt = _dm.getTodayCount();
        var elapsed  = _dm.getSecondsSinceLastSmoke();
        var phase    = _dm.getRecoveryPhase();

        var phaseClr = 0x00E676;
        var phaseTxt = "Aman";
        if (elapsed >= 0) {
            if (phase == 0) {
                phaseClr = 0xFF3D3D;
                phaseTxt = "HR Naik";
            } else if (phase == 1) {
                phaseClr = 0xFF9800;
                phaseTxt = "CO Tinggi";
            } else {
                phaseClr = 0x00E676;
                phaseTxt = "Pulih";
            }
        }

        // Zona Atas, Tengah, Bawah pada kanvas Glance
        var topY = (h * 22) / 100;
        var barY = (h * 50) / 100;
        var botY = (h * 78) / 100;

        // ATAS: Sisa & Hari ini
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(2, topY, Graphics.FONT_XTINY, Lang.format("Sisa $1$/$2$  |  Hr: $3$", [packLeft, packSize, todayCnt]), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // TENGAH: Progress Bar
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(2, barY - 3, barW, 6, 3);

        var progress = 1.0f;
        if (elapsed >= 0) {
            progress = elapsed.toFloat() / 7200.0f;
            if (progress > 1.0f) { progress = 1.0f; }
            if (progress < 0.10f) { progress = 0.10f; }
        }
        var fillW = (barW * progress).toNumber();
        if (fillW < 6) { fillW = 6; }
        dc.setColor(phaseClr, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(2, barY - 3, fillW, 6, 3);

        // BAWAH: Status & Waktu
        var botStr = "Aman  |  Belum sebat";
        if (elapsed >= 0) {
            botStr = Lang.format("$1$  |  $2$", [phaseTxt, _dm.formatElapsed(elapsed)]);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(0x00E676, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(2, botY, Graphics.FONT_XTINY, botStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}