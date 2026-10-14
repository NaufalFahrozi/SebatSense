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

        var w = dc.getWidth();

        // ── Derive Display Values ─────────────────────────────────────────────
        var phase    = _dm.getRecoveryPhase();  // 0=Red 1=Orange 2=Green
        var phaseClr = Graphics.COLOR_RED;
        var phaseTxt = "HR Naik";
        if (phase == 1) {
            phaseClr = Graphics.COLOR_ORANGE;
            phaseTxt = "CO Tinggi";
        } else if (phase == 2) {
            phaseClr = Graphics.COLOR_GREEN;
            phaseTxt = "HR Pulih";
        }

        var packLeft   = _dm.getPackLeft();
        var packSize   = _dm.getPackSize();
        var todayCnt   = _dm.getTodayCount();
        var elapsed    = _dm.getSecondsSinceLastSmoke();
        var elapsedStr = _dm.formatElapsed(elapsed);
        var runOut     = _dm.getPredictedRunOutTime();

        // ── Row 1 (y=8): Title & Pack Stock ───────────────────────────────────
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(4, 8, Graphics.FONT_GLANCE, "SebatSense", Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 4, 8, Graphics.FONT_GLANCE,
            Lang.format("$1$/$2$ btg", [packLeft, packSize]),
            Graphics.TEXT_JUSTIFY_RIGHT);

        // ── Row 2 (y=40): Today Count & Recovery Badge ────────────────────────
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(4, 40, Graphics.FONT_XTINY,
            Lang.format("Hari ini: $1$ btg", [todayCnt]),
            Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(phaseClr, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 4, 40, Graphics.FONT_XTINY, phaseTxt, Graphics.TEXT_JUSTIFY_RIGHT);

        // ── Row 3 (y=70): Progress Bar ────────────────────────────────────────
        var barX = 4;
        var barW = w - 8;
        var barH = 5;
        var barY = 70;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barX, barY, barW, barH, 2);

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
            dc.fillRoundedRectangle(barX, barY, fillW, barH, 2);
        }

        // ── Row 4 (y=82): Last Smoke & Predicted Run-Out ──────────────────────
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(4, 82, Graphics.FONT_XTINY,
            Lang.format("$1$", [elapsedStr]),
            Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 4, 82, Graphics.FONT_XTINY,
            Lang.format("Habis: $1$", [runOut]),
            Graphics.TEXT_JUSTIFY_RIGHT);
    }
}
