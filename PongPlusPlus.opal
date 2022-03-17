package opal:     import *;
package random:   import uniform, randint;
package pygame:   import mixer;
package colorsys: import hsv_to_rgb;
import math, os;

new <Vector> RESOLUTION = Vector(1280, 720);

new bool DEBUG_MODE = False;

new tuple FG                     = (255, 255, 255),
          BG                     = (  0,   0,   0),
          KEYS                   = (K_SPACE, K_UP, K_w, K_RETURN),
          HITBOX_COLOR           = (255,   0,   0),
          INFO_COLOR             = (  0,   0, 255),
          SAFE_ZONE_COLOR        = (  0, 255,   0),
          FLYING_SAFE_ZONE_COLOR = (255, 255,   0);

new <Vector> GRAVITY            = Vector(0, 0.6),
             PAD_SIZE           = Vector(15, 100),
             PLAYER_VELOCITY    = Vector(5),
             OBSTACLE_SAFE_ZONE = Vector(100, 50);

new int PLAYER_SIZE           = 20,
        PAD_WALL_DISTANCE     = 40,
        FRAMERATE             = 60,
        PAD_MOVE_SPEED_MLT    = 3,
        TOLERANCE             = 2,
        ALPHA_CHANGE          = 100,
        BONUS_ALPHA_CHANGE    = 25,
        LIFESPAN_DECREASE     = 3,
        PARTICLE_SIZE         = 1,
        MIN_PARTICLE_QTY      = 25,
        MAX_PARTICLE_QTY      = 50,
        DAY_CYCLE             = 7200,
        MIN_OBSTACLE_SIZE     = 15,
        MAX_OBSTACLE_SIZE     = 40,
        MIN_OBSTACLE_LIFE     = 300,
        MAX_OBSTACLE_LIFE     = 900,
        OBSTACLE_START_ALPHA  = 30,
        OBSTACLE_DELTA_ALPHA  = 5,
        PLAYER_COUNT_OBST     = 10,
        PLAYER_SAFE_ZONE      = 40,
        MOD_INCREMENT_DIFF    = 5,
        MIN_FLYINGOBST_SPEED  = 5,
        MAX_FLYINGOBST_SPEED  = 15,
        START_DIFFICULTY      = 0,
        DEBUG_LINES_WIDTH     = 1,
        DEBUG_VELOCITY_LEN    = 40,
        BONUS_SIZE            = 20,
        BONUS_LIFE            = 150,
        BONUS_EFFECT_DUR      = 200,
        PLAYER_COUNT_BONUS    = 20,
        BONUS_PAD_DISTANCE    = 100,
        BONUS_PAD_Y_DIST      = 50,
        FLYING_SAFE_ZONE_SIZE = 100;

new float JUMP_VELOCITY                = 10,
          PARTICLE_VELOCITY_MULTIPLIER = 0.98,
          PARTICLE_MAX_INIT_VELOCITY   = 5,
          HOVER_AMPLITUDE              = 20,
          HOVER_ANGLE_INCREMENT        = 0.02,
          BONUS_ANGLE_INCREMENT        = 0.05,
          RAINBOW_DELTA                = 0.01;

new int HALF_BONUS_SIZE = BONUS_SIZE // 2;

new float EFFECTIVE_PAD_FRMT = FRAMERATE / PAD_MOVE_SPEED_MLT;

new <Vector> PLAYER_SIZE_VEC     = Vector(PLAYER_SIZE, PLAYER_SIZE),
             START_TEXT_POS      = Vector(RESOLUTION.x // 2, RESOLUTION.y // 4),
             CENTER              = RESOLUTION // 2,
             BONUS_SIZE_VEC      = Vector(BONUS_SIZE, BONUS_SIZE),
             HALF_BONUS_SIZE_VEC = BONUS_SIZE_VEC // 2,
             BONUS_PAD_SIZE      = Vector(PAD_SIZE.x, RESOLUTION.y - BONUS_PAD_Y_DIST * 2);

new <Graphics> graphics = Graphics(RESOLUTION, FRAMERATE, caption = "Pong++");

$include os.path.join("HOME_DIR", "particles.opal")

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

        this.__resetMvt();
    }
    
    new method __resetMvt() {
        this.__cnt  = 0;
        this.__step = 0;
    }

    new method __moveTo(pos) {
        if this.__size == PAD_SIZE {
            this.__cnt  = 0;
            this.__step = (pos - this.pos.y) / EFFECTIVE_PAD_FRMT;
        }
    }

    new method reset() {
        this.pos.y = RESOLUTION.y // 2 - this.__size.y // 2;
        this.__resetMvt();
    }

    new method update() {
        this.pos.y += this.__step;
        this.pos.y = int(this.pos.y);

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
                    tmp, Vector(TOLERANCE * 2, this.__size.y),
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
                    Vector(this.pos.x - TOLERANCE, this.pos.y),
                    Vector(TOLERANCE * 2, this.__size.y),
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
            if playerPosX in Utils.tolerance(tmp, TOLERANCE) and (playerPosY in r or playerPosY + PLAYER_SIZE in r) {
                this.__moveTo(randint(OBSTACLE_SAFE_ZONE.y, RESOLUTION.y - OBSTACLE_SAFE_ZONE.y - this.__size.y));
                return True;
            }
        } else {
            playerPosX += PLAYER_SIZE;

            if playerPosX in Utils.tolerance(this.pos.x, TOLERANCE) and (playerPosY in r or playerPosY + PLAYER_SIZE in r) {
                this.__moveTo(randint(OBSTACLE_SAFE_ZONE.y, RESOLUTION.y - OBSTACLE_SAFE_ZONE.y - this.__size.y));
                return True;
            }
        }

        return False;
    }
}

new class Player {
    new method __init__() {
        this.__reset();
        this.explosion = Explosion(this.pos);
    }

    new method __reset() {
        this.__hoverAngle = 0;

        this.count    = 0;
        this.playing  = False;
        this.dead     = False;
        this.pos      = CENTER.copy() - PLAYER_SIZE_VEC // 2;
        this.velocity = Vector();

        this.__rainbow    = False;
        this.__rainbowCnt = 0;
    }

    new method rainbowOn() {
        this.__rainbow    = True;
        this.__rainbowCnt = 0;
    }

    new method rainbowOff() {
        this.__rainbow = False;
    }

    new method start() {
        this.playing  = True;
        this.velocity = PLAYER_VELOCITY if randint(0, 1) == 0 else -PLAYER_VELOCITY;
    }

    new method invert() {
        this.count++;
        this.velocity.x = -this.velocity.x;
    }

    new method jump() {
        if not this.playing {
            this.start();
        }

        this.velocity.y = -JUMP_VELOCITY;
    }

    new method isDead() {
        if this.dead {
            this.explosion.explode(this.pos);
            this.__reset();

            return True;
        }

        if this.pos.x <= 0 {
            this.explosion.explode(Vector(0, this.pos.y));
        } elif this.pos.x + PLAYER_SIZE >= RESOLUTION.x {
            this.explosion.explode(Vector(RESOLUTION.x - 1, this.pos.y));
        } elif this.pos.y <= 0 {
            this.explosion.explode(Vector(this.pos.x, 0));
        } elif this.pos.y + PLAYER_SIZE >= RESOLUTION.y {
            this.explosion.explode(Vector(this.pos.x, RESOLUTION.y - 1));
        } else {
            return False;
        }

        this.__reset();
        return True;
    }

    new method update() {
        if this.explosion.isAlive() {
            this.explosion.update();
            this.explosion.show();
        } else {
            if this.playing {
                this.velocity += GRAVITY;
                this.pos      += this.velocity;

                if this.__rainbow {
                    graphics.fastRectangle(this.pos, PLAYER_SIZE_VEC, hsvToRgb(this.__rainbowCnt));

                    this.__rainbowCnt += RAINBOW_DELTA;
                    if this.__rainbowCnt > 1 {
                        this.__rainbowCnt = 0;
                    }
                } else {
                    graphics.fastRectangle(this.pos, PLAYER_SIZE_VEC, FG);
                }
            } else {
                new dynamic tmpPos = this.pos.copy();
                tmpPos.y += round(math.sin(this.__hoverAngle) * HOVER_AMPLITUDE);
                graphics.fastRectangle(tmpPos, PLAYER_SIZE_VEC, FG);
                this.__hoverAngle += HOVER_ANGLE_INCREMENT;
            }

            if DEBUG_MODE {
                new dynamic center = this.pos + PLAYER_SIZE_VEC // 2,
                            vel    = this.velocity.copy();
                graphics.fastRectangle(this.pos, PLAYER_SIZE_VEC, HITBOX_COLOR, DEBUG_LINES_WIDTH);
                graphics.line(center, center + vel.magnitude(DEBUG_VELOCITY_LEN), INFO_COLOR, DEBUG_LINES_WIDTH);

                graphics.fastRectangle(this.pos - PLAYER_SAFE_ZONE, PLAYER_SIZE_VEC + PLAYER_SAFE_ZONE * 2, SAFE_ZONE_COLOR, DEBUG_LINES_WIDTH);
            }
        }
    }
}

new function hsvToRgb(h, s = 1, v = 1) {
    return tuple(round(i * 255) for i in hsv_to_rgb(h, s, v));
}

$include os.path.join("HOME_DIR", "Obstacle.opal")
$include os.path.join("HOME_DIR", "FlyingObstacle.opal")
$include os.path.join("HOME_DIR", "Bonus.opal")

new class Game {
    new method __init__() {
        this.__dayCounter = 0;

        this.leftPad  = Pad(True);
        this.rightPad = Pad(False);

        this.player = Player();

        this.__resetPart();

        mixer.init();
        this.__hitSound   = mixer.Sound(os.path.join("HOME_DIR", "sounds", "hit.mp3"));
        this.__deathSound = mixer.Sound(os.path.join("HOME_DIR", "sounds", "death.mp3"));
        this.__bonusSound = mixer.Sound(os.path.join("HOME_DIR", "sounds", "bonus.mp3"));

        graphics.event(KEYDOWN)(this.__jump);
        graphics.event(MOUSEBUTTONDOWN)(this.__jumpClick);
        graphics.update(this.update);
    }

    new method __resetCustomPads() {
        this.customLeftPad  = None;
        this.customRightPad = None;
        this.__alphaChange  = ALPHA_CHANGE;
    }

    new method __resetPart() {
        this.__difficulty   = START_DIFFICULTY;
        this.__lastCount    = 0;
        this.obstacles      = [];
        this.bonus          = None;
        this.__customPadCnt = 0;

        this.__resetCustomPads();
    }

    new method __reset() {
        this.__resetPart();
        this.player.rainbowOff();
        this.leftPad.reset();
        this.rightPad.reset();
    }

    new method isSafe(pos) {
        return (pos.x < this.player.pos.x - PLAYER_SAFE_ZONE or
                pos.x > this.player.pos.x + PLAYER_SIZE + PLAYER_SAFE_ZONE) and
               (pos.y < this.player.pos.y - PLAYER_SAFE_ZONE or
                pos.y > this.player.pos.y + PLAYER_SIZE + PLAYER_SAFE_ZONE);
    }

    new method getSafePos() {
        new dynamic tmp;

        do not this.isSafe(tmp) {
            tmp = Vector(
                randint(
                    OBSTACLE_SAFE_ZONE.x,
                    RESOLUTION.x - OBSTACLE_SAFE_ZONE.x
                ),
                randint(
                    OBSTACLE_SAFE_ZONE.y,
                    RESOLUTION.y - OBSTACLE_SAFE_ZONE.y
                )
            );
        }

        return tmp;
    }

    new method isPlayerInFlyingSafeLeft() {
        return (this.leftPad.pos.x < this.player.pos.x < this.leftPad.pos.x + FLYING_SAFE_ZONE_SIZE and
                this.leftPad.pos.y < this.player.pos.y < this.leftPad.pos.y + PAD_SIZE) or
               (this.leftPad.pos.x < this.player.pos.x + PLAYER_SIZE < this.leftPad.pos.x + FLYING_SAFE_ZONE_SIZE and
                this.leftPad.pos.y < this.player.pos.y + PLAYER_SIZE < this.leftPad.pos.y + PAD_SIZE);
    }

    new method isPlayerInFlyingSafeRight() {
        return (this.rightPad.pos.x - FLYING_SAFE_ZONE_SIZE < this.player.pos.x < this.rightPad.pos.x and
                this.rightPad.pos.y < this.player.pos.y < this.rightPad.pos.y + PAD_SIZE) or
               (this.rightPad.pos.x - FLYING_SAFE_ZONE_SIZE < this.player.pos.x + PLAYER_SIZE < this.rightPad.pos.x and
                this.rightPad.pos.y < this.player.pos.y + PLAYER_SIZE < this.rightPad.pos.y + PAD_SIZE);
    }

    new method getFlyingSafePos() {
        new dynamic mode = randint(0, 3);

        match mode {
            case FlyingObstacle.LEFT {
                if (this.customLeftPad is None and this.customRightPad is None) or this.isPlayerInFlyingSafeLeft() {
                    if randint(0, 1) == 0 {
                        return Vector(0, randint(OBSTACLE_SAFE_ZONE.y, this.leftPad.pos.y)), mode;
                    } else {
                        return Vector(0, randint(this.leftPad.pos.y + PAD_SIZE.y, RESOLUTION.y - OBSTACLE_SAFE_ZONE.y)), mode;
                    }
                } else {
                    return Vector(0, randint(OBSTACLE_SAFE_ZONE.y, RESOLUTION.y - OBSTACLE_SAFE_ZONE.y)), mode;
                }
            }
            case FlyingObstacle.RIGHT {
                if (this.customLeftPad is None and this.customRightPad is None) or this.isPlayerInFlyingSafeRight() {
                    if randint(0, 1) == 0 {
                        return Vector(RESOLUTION.x, randint(OBSTACLE_SAFE_ZONE.y, this.rightPad.pos.y)), mode;
                    } else {
                        return Vector(RESOLUTION.x, randint(this.rightPad.pos.y + PAD_SIZE.y, RESOLUTION.y - OBSTACLE_SAFE_ZONE.y)), mode;
                    }
                } else {
                    return Vector(RESOLUTION.x, randint(OBSTACLE_SAFE_ZONE.y, RESOLUTION.y - OBSTACLE_SAFE_ZONE.y)), mode;
                }
            }
            case FlyingObstacle.TOP {
                return Vector(randint(OBSTACLE_SAFE_ZONE.x, RESOLUTION.x - OBSTACLE_SAFE_ZONE.x), 0), mode;
            }
            case FlyingObstacle.BOTTOM {
                return Vector(randint(OBSTACLE_SAFE_ZONE.x, RESOLUTION.x - OBSTACLE_SAFE_ZONE.x), RESOLUTION.y), mode;
            }
        }
    }

    new method __jump(event) {
        global DEBUG_MODE;

        if event.key in KEYS and not this.player.isDead() and
                                (not this.player.explosion.isAlive()) {
            this.player.jump();
        } elif event.key == K_F3 {
            !DEBUG_MODE;
        }
    }

    new method __jumpClick(event) {
        if event.button == 1 {
            this.player.jump();
        }
    }

    new method __invert() {
        mixer.Sound.play(this.__hitSound);
        this.player.invert();
    }

    new method update() {
        global BG, FG;

        if this.player.playing {
            graphics.simpleText(str(this.player.count), CENTER, FG, True, True);
        }

        graphics.fillAlpha(BG, this.__alphaChange);

        if this.player.isDead() {
            mixer.Sound.play(this.__deathSound);
            this.__reset();
        }

        if this.player.playing {
            if this.customLeftPad is not None and this.customRightPad is not None {
                if this.__customPadCnt == 0 {
                    this.player.rainbowOff();
                    this.__resetCustomPads();
                } else {
                    this.customLeftPad.update();
                    this.customRightPad.update();

                    if this.customLeftPad.collides(this.player) or this.customRightPad.collides(this.player) {
                        this.__invert();
                    }

                    this.__customPadCnt--;
                }
            } else {
                this.leftPad.update();
                this.rightPad.update();

                if this.leftPad.collides(this.player) or this.rightPad.collides(this.player) {
                    this.__invert();
                }

                if this.bonus is not None {
                    if not this.bonus.isAlive() {
                        this.bonus = None;
                    } else {
                        this.bonus.update();

                        if this.bonus.collides(this.player) {
                            this.bonus = None;

                            this.__customPadCnt = BONUS_EFFECT_DUR;
                            new dynamic xPos = this.player.pos.x + PLAYER_SIZE // 2;

                            this.player.pos = CENTER.copy();

                            this.customLeftPad  = Pad( True, Vector(CENTER.x - BONUS_PAD_DISTANCE - BONUS_PAD_SIZE.x, BONUS_PAD_Y_DIST), BONUS_PAD_SIZE);
                            this.customRightPad = Pad(False, Vector(CENTER.x + BONUS_PAD_DISTANCE, BONUS_PAD_Y_DIST), BONUS_PAD_SIZE);

                            this.__alphaChange = BONUS_ALPHA_CHANGE;
                            this.player.rainbowOn();

                            mixer.Sound.play(this.__bonusSound);
                        }
                    }
                } elif this.player.count >= PLAYER_COUNT_BONUS and this.player.playing {
                    if randint(0, 2500) < 1 {
                        this.bonus = Bonus(this.getSafePos());
                    }
                }
            }

            if this.player.count >= PLAYER_COUNT_OBST {
                if this.player.count != this.__lastCount and this.player.count % MOD_INCREMENT_DIFF == 0 {
                    this.__lastCount = this.player.count;
                    this.__difficulty++;
                }

                if randint(0, 1000) < this.__difficulty {
                    this.obstacles.append(Obstacle(this.getSafePos()));
                } elif randint(0, 1000) < this.__difficulty {
                    this.obstacles.append(FlyingObstacle(*this.getFlyingSafePos()));
                }
            }

            this.obstacles = [obstacle for obstacle in this.obstacles if obstacle.isAlive()];

            for obstacle in this.obstacles {
                obstacle.update();

                if obstacle.collides(this.player) {
                    this.player.dead = True;
                    return;
                }
            }
        } elif not this.player.explosion.isAlive() {
            graphics.simpleText("JUMP TO START", START_TEXT_POS, FG, True, True);
        }

        this.__dayCounter++;
        if this.__dayCounter == DAY_CYCLE {
            this.__dayCounter = 0;
            unchecked: BG, FG = FG, BG;
        }

        this.player.update();

        if DEBUG_MODE {
            graphics.fastRectangle(OBSTACLE_SAFE_ZONE, RESOLUTION - OBSTACLE_SAFE_ZONE * 2, SAFE_ZONE_COLOR, DEBUG_LINES_WIDTH);
        }
    }

    new method run() {
        graphics.fill(BG);
        graphics.run(drawBackground = False);
    }
}

main {
    Game().run();
}
