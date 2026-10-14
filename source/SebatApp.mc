import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// ─────────────────────────────────────────────────────────────────────────────
// SebatApp – Application entry-point
// ─────────────────────────────────────────────────────────────────────────────
class SebatApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {}

    function onStop(state as Dictionary?) as Void {}

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view     = new SebatView();
        var delegate = new SebatDelegate(view);
        return [view, delegate];
    }

    // Glance entry-point – must be annotated (:glance)
    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or
                                [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or
                                Null {
        return [new SebatGlanceView()];
    }
}
