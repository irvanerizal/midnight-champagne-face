import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module Icons {

    //! Draw a simple vector icon centered at (x, y) inside a box of side s px.
    //! level is only used by :battery and is in the range 0..1.
    public function draw(dc as Dc, kind as Symbol, x as Numeric, y as Numeric,
            s as Numeric, color as Number, level as Numeric) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        var pen = Math.round(0.1 * s).toNumber();
        if (pen < 1) {
            pen = 1;
        }
        dc.setPenWidth(pen);

        if (kind == :battery) {
            var bx = Math.round(x - 0.45 * s).toNumber();
            var by = Math.round(y - 0.28 * s).toNumber();
            var bw = Math.round(0.9 * s).toNumber();
            var bh = Math.round(0.56 * s).toNumber();
            dc.drawRectangle(bx, by, bw, bh);

            // Terminal nub on the right side.
            dc.fillRectangle(
                Math.round(x + 0.47 * s).toNumber(),
                Math.round(y - 0.13 * s).toNumber(),
                atLeast1(Math.round(0.12 * s).toNumber()),
                atLeast1(Math.round(0.26 * s).toNumber()));

            // Charge level, inset from the outline's left and top.
            if (level > 0) {
                var iw = Math.round(0.72 * s * level).toNumber();
                if (iw > 0) {
                    dc.fillRectangle(
                        Math.round(bx + 0.09 * s).toNumber(),
                        Math.round(by + 0.09 * s).toNumber(),
                        iw,
                        atLeast1(Math.round(0.38 * s).toNumber()));
                }
            }
        } else if (kind == :steps) {
            dc.fillEllipse(
                Math.round(x - 0.2 * s).toNumber(),
                Math.round(y - 0.2 * s).toNumber(),
                atLeast1(Math.round(0.17 * s).toNumber()),
                atLeast1(Math.round(0.28 * s).toNumber()));
            dc.fillEllipse(
                Math.round(x + 0.22 * s).toNumber(),
                Math.round(y + 0.2 * s).toNumber(),
                atLeast1(Math.round(0.17 * s).toNumber()),
                atLeast1(Math.round(0.28 * s).toNumber()));
        } else if (kind == :heart) {
            dc.fillPolygon([
                [Math.round(x + 0.000 * s).toNumber(), Math.round(y - 0.212 * s).toNumber()],
                [Math.round(x + 0.008 * s).toNumber(), Math.round(y - 0.248 * s).toNumber()],
                [Math.round(x + 0.055 * s).toNumber(), Math.round(y - 0.329 * s).toNumber()],
                [Math.round(x + 0.156 * s).toNumber(), Math.round(y - 0.393 * s).toNumber()],
                [Math.round(x + 0.286 * s).toNumber(), Math.round(y - 0.390 * s).toNumber()],
                [Math.round(x + 0.397 * s).toNumber(), Math.round(y - 0.311 * s).toNumber()],
                [Math.round(x + 0.440 * s).toNumber(), Math.round(y - 0.184 * s).toNumber()],
                [Math.round(x + 0.397 * s).toNumber(), Math.round(y - 0.048 * s).toNumber()],
                [Math.round(x + 0.286 * s).toNumber(), Math.round(y + 0.077 * s).toNumber()],
                [Math.round(x + 0.156 * s).toNumber(), Math.round(y + 0.190 * s).toNumber()],
                [Math.round(x + 0.055 * s).toNumber(), Math.round(y + 0.290 * s).toNumber()],
                [Math.round(x + 0.008 * s).toNumber(), Math.round(y + 0.365 * s).toNumber()],
                [Math.round(x + 0.000 * s).toNumber(), Math.round(y + 0.393 * s).toNumber()],
                [Math.round(x - 0.008 * s).toNumber(), Math.round(y + 0.365 * s).toNumber()],
                [Math.round(x - 0.055 * s).toNumber(), Math.round(y + 0.290 * s).toNumber()],
                [Math.round(x - 0.156 * s).toNumber(), Math.round(y + 0.190 * s).toNumber()],
                [Math.round(x - 0.286 * s).toNumber(), Math.round(y + 0.077 * s).toNumber()],
                [Math.round(x - 0.397 * s).toNumber(), Math.round(y - 0.048 * s).toNumber()],
                [Math.round(x - 0.440 * s).toNumber(), Math.round(y - 0.184 * s).toNumber()],
                [Math.round(x - 0.397 * s).toNumber(), Math.round(y - 0.311 * s).toNumber()],
                [Math.round(x - 0.286 * s).toNumber(), Math.round(y - 0.390 * s).toNumber()],
                [Math.round(x - 0.156 * s).toNumber(), Math.round(y - 0.393 * s).toNumber()],
                [Math.round(x - 0.055 * s).toNumber(), Math.round(y - 0.329 * s).toNumber()],
                [Math.round(x - 0.008 * s).toNumber(), Math.round(y - 0.248 * s).toNumber()]
            ] as Array<Graphics.Point2D>);
        }
    }

    function atLeast1(value as Number) as Number {
        return value < 1 ? 1 : value;
    }
}
