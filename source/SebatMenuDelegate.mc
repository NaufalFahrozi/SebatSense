import Toybox.Lang;
import Toybox.WatchUi;

// ─────────────────────────────────────────────────────────────────────────────
// SebatMenuDelegate – Menu2InputDelegate
//
// Handles item selection for three menu contexts:
//   :stockMenu    – manual log / open pack / remove one
//   :settingsMenu – pack-size picker / price picker / reset today
//   :packSizeMenu – 12 / 16 / 20 batang
//   :packPriceMenu– price selection
// ─────────────────────────────────────────────────────────────────────────────
class SebatMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view     as SebatView;
    private var _menuType as Symbol;

    function initialize(view as SebatView, menuType as Symbol) {
        Menu2InputDelegate.initialize();
        _view     = view;
        _menuType = menuType;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as Symbol;
        var dm = _view.getDataManager();

        if (_menuType == :stockMenu) {
            if      (id == :manualLog)   { dm.manualLog();  }
            else if (id == :openNewPack) { dm.openNewPack(); }
            else if (id == :removeOne)   { dm.removeOneLog(); }
            _view.reloadData();
            WatchUi.popView(WatchUi.SLIDE_DOWN);

        } else if (_menuType == :settingsMenu) {
            if (id == :packSize) {
                pushPackSizeMenu();
                return; // don't pop – we're pushing a sub-menu
            } else if (id == :packPrice) {
                pushPackPriceMenu();
                return;
            } else if (id == :resetToday) {
                dm.resetToday();
                _view.reloadData();
                WatchUi.popView(WatchUi.SLIDE_DOWN);
            }

        } else if (_menuType == :packSizeMenu) {
            if      (id == :size12) { dm.setPackSize(12); }
            else if (id == :size16) { dm.setPackSize(16); }
            else if (id == :size20) { dm.setPackSize(20); }
            _view.reloadData();
            // Pop size picker + settings menu (back to dashboard)
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);

        } else if (_menuType == :packPriceMenu) {
            if      (id == :p25000) { dm.setPackPrice(25000); }
            else if (id == :p30000) { dm.setPackPrice(30000); }
            else if (id == :p32000) { dm.setPackPrice(32000); }
            else if (id == :p35000) { dm.setPackPrice(35000); }
            else if (id == :p38000) { dm.setPackPrice(38000); }
            else if (id == :p40000) { dm.setPackPrice(40000); }
            else if (id == :p45000) { dm.setPackPrice(45000); }
            else if (id == :p50000) { dm.setPackPrice(50000); }
            _view.reloadData();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    // ── Sub-menu: Pack Size ───────────────────────────────────────────────────
    private function pushPackSizeMenu() as Void {
        var menu = new WatchUi.Menu2({:title => "Isi Bungkus"});
        menu.addItem(new WatchUi.MenuItem("12 Batang", null, :size12, {}));
        menu.addItem(new WatchUi.MenuItem("16 Batang", null, :size16, {}));
        menu.addItem(new WatchUi.MenuItem("20 Batang", null, :size20, {}));
        WatchUi.pushView(menu,
            new SebatMenuDelegate(_view, :packSizeMenu),
            WatchUi.SLIDE_UP);
    }

    // ── Sub-menu: Pack Price ──────────────────────────────────────────────────
    private function pushPackPriceMenu() as Void {
        var menu = new WatchUi.Menu2({:title => "Harga Bungkus"});
        menu.addItem(new WatchUi.MenuItem("Rp 25.000", null, :p25000, {}));
        menu.addItem(new WatchUi.MenuItem("Rp 30.000", null, :p30000, {}));
        menu.addItem(new WatchUi.MenuItem("Rp 32.000", null, :p32000, {}));
        menu.addItem(new WatchUi.MenuItem("Rp 35.000", null, :p35000, {}));
        menu.addItem(new WatchUi.MenuItem("Rp 38.000", null, :p38000, {}));
        menu.addItem(new WatchUi.MenuItem("Rp 40.000", null, :p40000, {}));
        menu.addItem(new WatchUi.MenuItem("Rp 45.000", null, :p45000, {}));
        menu.addItem(new WatchUi.MenuItem("Rp 50.000", null, :p50000, {}));
        WatchUi.pushView(menu,
            new SebatMenuDelegate(_view, :packPriceMenu),
            WatchUi.SLIDE_UP);
    }
}
