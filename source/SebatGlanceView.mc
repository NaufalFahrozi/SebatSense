import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// ─────────────────────────────────────────────────────────────────────────────
// SebatGlanceView  (:glance)
// Rendered in the glance strip – extremely constrained memory budget.
// Layout uses glance canvas (~390 x ~110 px, exact size varies).
// ─────────────────────────────────────────────────────────────────────────────
(:glance)
class SebatGlanceView extends WatchUi.GlanceView {

    private var _dm as SebatDataManager;

    (:glance)
    function initialize() {
        GlanceView.initialize();
        _dm = new SebatDataManager();
    }

    (:glance)
    function onUpdate(dc as Graphics.Dc) as Void {
        // ── Background ────────────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w  = dc.getWidth();
        var cx = w / 2;

        // ── Derive Display Values ─────────────────────────────────────────────
        var phase    = _dm.getRecoveryPhase();  // 0=Red 1=Orange 2=Green
        var phaseClr = Graphics.COLOR_RED;
        var phaseTxt = "HR/Tensi Naik";
        if (phase == 1) {
            phaseClr = Graphics.COLOR_ORANGE;
            phaseTxt = "CO Darah Tinggi";
        } else if (phase == 2) {
            phaseClr = Graphics.COLOR_GREEN;
            phaseTxt = "O2 & HR Pulih";
        }

        var packLeft   = _dm.getPackLeft();
        var packSize   = _dm.getPackSize();
        var todayCnt   = _dm.getTodayCount();
        var elapsed    = _dm.getSecondsSinceLastSmoke();
        var elapsedStr = _dm.formatElapsed(elapsed);
        var runOut     = _dm.getPredictedRunOutTime();

        var y = 2;

        // ── Row 1: Pack Remaining ─────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY,
            Lang.format("Sisa: $1$/$2$ btg", [packLeft, packSize]),
            Graphics.TEXT_JUSTIFY_CENTER);
        y += 20;

        // ── Row 2: Today Count ────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY,
            Lang.format("Hari ini: $1$ batang", [todayCnt]),
            Graphics.TEXT_JUSTIFY_CENTER);
        y += 16;

        // ── Row 3: Recovery Phase Badge ───────────────────────────────────────
        dc.setColor(phaseClr, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, phaseTxt, Graphics.TEXT_JUSTIFY_CENTER);
        y += 14;

        // ── Row 4: Progress Bar ───────────────────────────────────────────────
        var barX  = 8;
        var barW  = w - 16;
        var barH  = 5;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barX, y, barW, barH, 2);

        var progress = 0.0f;
        if (phase == 0 && elapsed > 0) {
            progress = (elapsed.toFloat() / 1200.0f);
        } else if (phase == 1) {
            progress = ((elapsed - 1200).toFloat() / 6000.0f);
        } else if (phase == 2) {
            progress = 1.0f;
        }
        if (progress > 1.0f) { progress = 1.0f; }
        var fillW = (barW.toFloat() * progress).toNumber();
        if (fillW > 0) {
            dc.setColor(phaseClr, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, y, fillW, barH, 2);
        }
        y += 13;

        // ── Row 5: Last Smoke ─────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY,
            Lang.format("Terakhir: $1$", [elapsedStr]),
            Graphics.TEXT_JUSTIFY_CENTER);
        y += 15;

        // ── Row 6: Predicted Run-Out ──────────────────────────────────────────
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY,
            Lang.format("Habis: $1$", [runOut]),
            Graphics.TEXT_JUSTIFY_CENTER);
    }
}
