new class Pad {
    new method __init__(isLeft, pos = None, size = PAD_SIZE) {
        if pos is None {
            if isLeft {
                this.pos = Vector(PAD_WALL_DISTANCE, RESOLUTION.y // 2 - size.y // 2);
            } else {
                this.pos = Vector(RESOLUTION.x - PAD_WALL_DISTANCE - size.x, RESOLUTION.y // 2 - size.y // 2);
            }
        } else {
            this.pos = pos;
        }

        this.__size = size;

        this.isLeft = isLeft;

        this.__cnt  = 0;
        this.__step = 0;

        this.__computeBounds();
    }

    new method __computeBounds() {
        if not RAYCASTING {
            return;
        }
        
        this.boundaries = [
            Boundary(
                this.pos, Vector(this.pos.x + this.__size.x, this.pos.y)
            ),
            Boundary(
                Vector(this.pos.x + this.__size.x, this.pos.y),
                this.pos + this.__size
            ),
            Boundary(
                this.pos + this.__size,
                Vector(this.pos.x, this.pos.y + this.__size.y)
            ),
            Boundary(
                Vector(this.pos.x, this.pos.y + this.__size.y),
                this.pos
            )
        ];
    }

    new method __moveTo(pos) {
        if this.__size == PAD_SIZE {
            this.__cnt  = 0;
            this.__step = (pos - this.pos.y) / EFFECTIVE_PAD_FRMT;
        }
    }

    new method reset() {
        this.pos.y = RESOLUTION.y // 2 - this.__size.y // 2;
        this.__step = 0;
        this.__computeBounds();
    }

    new method update() {
        this.pos.y += this.__step;
        this.pos.y = int(this.pos.y);

        this.__computeBounds();

        this.__cnt++;
        if this.__cnt == EFFECTIVE_PAD_FRMT {
            this.__step = 0;
        }

        graphics.fastRectangle(this.pos, this.__size, FG);

        if DEBUG_MODE {
            if this.isLeft {
                new dynamic tmp = Vector(this.pos.x + this.__size.x - TOLERANCE, this.pos.y);

                if this.__size == PAD_SIZE {
                    graphics.fastRectangle(
                        tmp, Vector(TOLERANCE + FLYING_SAFE_ZONE_SIZE, this.__size.y),
                        FLYING_SAFE_ZONE_COLOR, DEBUG_LINES_WIDTH
                    );
                }

                graphics.fastRectangle(
                    tmp, Vector(TOLERANCE, this.__size.y),
                    HITBOX_COLOR, DEBUG_LINES_WIDTH
                );
            } else {
                if this.__size == PAD_SIZE {
                    graphics.fastRectangle(
                        Vector(this.pos.x - FLYING_SAFE_ZONE_SIZE, this.pos.y),
                        Vector(FLYING_SAFE_ZONE_SIZE, this.__size.y),
                        FLYING_SAFE_ZONE_COLOR, DEBUG_LINES_WIDTH
                    );
                }

                graphics.fastRectangle(
                    this.pos,
                    Vector(TOLERANCE, this.__size.y),
                    HITBOX_COLOR, DEBUG_LINES_WIDTH
                );
            }

            if this.__step != 0 {
                new dynamic a = this.pos + this.__size // 2,
                            b = a.copy();

                b.y += this.__step * (EFFECTIVE_PAD_FRMT - this.__cnt);
                graphics.line(a, b, INFO_COLOR, DEBUG_LINES_WIDTH);
            }
        }
    }

    new method collides(player) {
        new dynamic r = range(this.pos.y, this.pos.y + this.__size.y);
        new int     playerPosY = player.pos.y;
        new dynamic playerPosX = player.pos.x;

        if this.isLeft {
            new dynamic tmp = this.pos.x + this.__size.x;
            if playerPosX in range(tmp - TOLERANCE, tmp) and (playerPosY in r or playerPosY + PLAYER_SIZE in r) {
                this.__moveTo(randint(OBSTACLE_SAFE_ZONE.y, RESOLUTION.y - OBSTACLE_SAFE_ZONE.y - this.__size.y));
                return True;
            }
        } else {
            playerPosX += PLAYER_SIZE;

            if playerPosX in range(this.pos.x, this.pos.x + TOLERANCE) and (playerPosY in r or playerPosY + PLAYER_SIZE in r) {
                this.__moveTo(randint(OBSTACLE_SAFE_ZONE.y, RESOLUTION.y - OBSTACLE_SAFE_ZONE.y - this.__size.y));
                return True;
            }
        }

        return False;
    }
}