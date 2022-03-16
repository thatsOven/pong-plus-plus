new class Bonus : Obstacle {
    new method __init__(pos) {
        this.pos = pos - HALF_BONUS_SIZE_VEC;
        this.__center = pos;

        this.size = BONUS_SIZE_VEC;

        this.__angle = 0;

        this.__pts = [
            this.pos.copy(),
            this.pos + BONUS_SIZE_VEC
        ];

        this.__pts[0].x += HALF_BONUS_SIZE;
        this.__pts[1].x -= HALF_BONUS_SIZE;

        this.alpha = BONUS_LIFE;

        this.__colorCnt = 0;
    }

    new method update() {
        new dynamic sideSize = round(math.sin(this.__angle) * HALF_BONUS_SIZE),
                    pt1      = this.__center.copy(),
                    pt2      = pt1.copy();
        pt1.x -= sideSize;
        pt2.x += sideSize;

        graphics.polygon((pt1, this.__pts[0], pt2, this.__pts[1]), hsvToRgb(this.__colorCnt));
        this.alpha--;

        this.__colorCnt += RAINBOW_DELTA;
        if this.__colorCnt > 1 {
            this.__colorCnt = 0;
        }

        this.__angle += BONUS_ANGLE_INCREMENT;

        if DEBUG_MODE {
            graphics.fastRectangle(this.pos, this.size, HITBOX_COLOR, DEBUG_LINES_WIDTH);
        }
    }
}