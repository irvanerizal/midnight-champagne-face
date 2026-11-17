import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class MidnightChampagneApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new MidnightChampagneView() ];
    }
}
