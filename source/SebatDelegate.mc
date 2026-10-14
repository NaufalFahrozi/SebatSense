import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// ─────────────────────────────────────────────────────────────────────────────
// SebatDelegate – BehaviorDelegate
//
// Countdown mode  : any select/tap → undo auto-log, enter dashboard
// Dashboard mode  : swipe/page buttons navigate pages;
//                   START on page 2 → stock action menu
//                   START on page 3 → settings menu
// ─────────────────────────────────────────────────────────────────────────────
class SebatDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SebatView;

    function initialize(view as SebatView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // ── START button ──────────────────────────────────────────────────────────
    function onSelect() as Boolean {
        if (_view.getMode() == SebatView.MODE_COUNTDOWN) {
            _view.undoAndEnterDashboard();
        } else {
            var page = _view.getPage();
            if (page == SebatView.PAGE_STOCK) {
                pushStockMenu();
            } else if (page == SebatView.PAGE_SETTINGS) {
                pushSettingsMenu();
            }
        }
        return true;
    }

    // ── Touchscreen tap (mirrors START on interactive pages) ─────────────────
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (_view.getMode() == SebatView.MODE_COUNTDOWN) {
            _view.undoAndEnterDashboard();
            return true;
        } else {
            var page = _view.getPage();
            if (page == SebatView.PAGE_STOCK) {
                pushStockMenu();
                return true;
            } else if (page == SebatView.PAGE_SETTINGS) {
                pushSettingsMenu();
                return true;
            }
        }
        return false;
    }

    // ── Swipe gestures → page navigation ─────────────────────────────────────
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        if (_view.getMode() == SebatView.MODE_DASHBOARD) {
            var dir = swipeEvent.getDirection();
            if (dir == WatchUi.SWIPE_UP || dir == WatchUi.SWIPE_LEFT) {
                _view.nextPage();
                return true;
            }
            if (dir == WatchUi.SWIPE_DOWN || dir == WatchUi.SWIPE_RIGHT) {
                _view.previousPage();
                return true;
            }
        }
        return false;
    }

    // ── Physical page-up / page-down buttons ─────────────────────────────────
    function onNextPage() as Boolean {
        if (_view.getMode() == SebatView.MODE_DASHBOARD) {
            _view.nextPage();
            return true;
        }
        return false;
    }

    function onPreviousPage() as Boolean {
        if (_view.getMode() == SebatView.MODE_DASHBOARD) {
            _view.previousPage();
            return true;
        }
        return false;
    }

    // ── BACK button: exit from dashboard ─────────────────────────────────────
    function onBack() as Boolean {
        if (_view.getMode() == SebatView.MODE_DASHBOARD) {
            System.exit();
        }
        return false;
    }

    // ── Stock Action Menu (Page 2) ────────────────────────────────────────────
    private function pushStockMenu() as Void {
        var menu = new WatchUi.Menu2({:title => "Aksi Rokok"});
        menu.addItem(new WatchUi.MenuItem(
            "Catat 1 Batang Manual", "Log tanpa keluar", :manualLog, {}));
        menu.addItem(new WatchUi.MenuItem(
            "Buka Bungkus Baru", "Reset stok penuh", :openNewPack, {}));
        menu.addItem(new WatchUi.MenuItem(
            "Kurangi 1 Catatan", "Koreksi -1", :removeOne, {}));
        WatchUi.pushView(menu,
            new SebatMenuDelegate(_view, :stockMenu),
            WatchUi.SLIDE_UP);
    }

    // ── Settings Menu (Page 4) ────────────────────────────────────────────────
    private function pushSettingsMenu() as Void {
        var menu = new WatchUi.Menu2({:title => "Pengaturan"});
        menu.addItem(new WatchUi.MenuItem(
            "Isi Bungkus", "12 / 16 / 20 btg", :packSize, {}));
        menu.addItem(new WatchUi.MenuItem(
            "Harga Bungkus", "Pilih harga", :packPrice, {}));
        menu.addItem(new WatchUi.MenuItem(
            "Reset Data Hari Ini", "Nol-kan hitungan hari ini", :resetToday, {}));
        WatchUi.pushView(menu,
            new SebatMenuDelegate(_view, :settingsMenu),
            WatchUi.SLIDE_UP);
    }
}
