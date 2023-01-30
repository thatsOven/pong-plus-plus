package opal:     import *;
package random:   import uniform, randint;
package pygame:   import mixer, Surface;
package colorsys: import hsv_to_rgb;
import math, os, sys, json;

new <Vector> RESOLUTION = Vector(1280, 720);

new bool DEBUG_MODE = False,
         RAYCASTING = True;

new tuple FG                     = (255, 255, 255),
          BG                     = (  0,   0,   0),
          KEYS                   = (K_SPACE, K_UP, K_w, K_RETURN),
          SPRINT_KEYS            = (K_c, K_z, K_RIGHT, K_LEFT),
          HITBOX_COLOR           = (255,   0,   0),
          INFO_COLOR             = (  0,   0, 255),
          SAFE_ZONE_COLOR        = (  0, 255,   0),
          FLYING_SAFE_ZONE_COLOR = (255, 255,   0),
          RAY_COLOR              = (255, 143, 246);

new <Vector> GRAVITY             = Vector(0, 0.6),
             PAD_SIZE            = Vector(15, 100),
             PLAYER_VELOCITY     = Vector(5),
             OBSTACLE_SAFE_ZONE  = Vector(100, 50),
             SPRINT_LINE_POS     = Vector(40, 40),
             LIGHTNING_LINE_RPOS = Vector(20, 26);

new int PLAYER_SIZE           = 20,
        PAD_WALL_DISTANCE     = 40,
        FRAMERATE             = 60,
        PAD_MOVE_SPEED_MLT    = 3,
        TOLERANCE             = 15,
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
        FLYING_SAFE_ZONE_SIZE = 100,
        SPRINT_CHARGE_DELTA   = 1,
        SPRINT_MAX_VALUE      = 900,
        SPRINT_USE_DELTA      = 10,
        SPRINT_VELOCITY       = 15,
        SPRINT_ALPHA_CHANGE   = 40,
        SHAKE                 = 2,
        SPRINT_LINE_LENGTH    = 200,
        SPRINT_LINE_WIDTH     = 4,
        SPRINT_COOLDOWN       = 30,
        HIT_COOLDOWN          = 5,
        LIGHTNING_SIZE        = 28,
        RAYS_QTY              = 360,
        BENCH_FRAMES          = 1000,
        MAX_RAYS              = 3600,
        MIN_RAYS              = 36,
        FLYING_CHANGE_EACH    = 10;

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
             BONUS_PAD_SIZE      = Vector(PAD_SIZE.x, RESOLUTION.y - BONUS_PAD_Y_DIST * 2),
             LIGHTNING_SIZE_VEC  = Vector(LIGHTNING_SIZE, LIGHTNING_SIZE),
             LIGHTNING_POS       = Vector(SPRINT_LINE_POS.x + SPRINT_LINE_LENGTH + LIGHTNING_LINE_RPOS.x, LIGHTNING_LINE_RPOS.y);

new <Graphics> graphics = Graphics(RESOLUTION, FRAMERATE, caption = "Pong++", showFps = True);

new function hsvToRgb(h, s = 1, v = 1) {
    return tuple(round(i * 255) for i in hsv_to_rgb(h, s, v));
}

$include os.path.join("HOME_DIR", "particles.opal")
$include os.path.join("HOME_DIR", "Boundary.opal")
$include os.path.join("HOME_DIR", "Ray.opal")
$include os.path.join("HOME_DIR", "Pad.opal")
$include os.path.join("HOME_DIR", "Player.opal")
$include os.path.join("HOME_DIR", "Obstacle.opal")
$include os.path.join("HOME_DIR", "FlyingObstacle.opal")
$include os.path.join("HOME_DIR", "Bonus.opal")

new class Game {
    new method __init__() {
        this.__dayCounter = 0;
        this.__color      = True;

        this.leftPad  = Pad(True);
        this.rightPad = Pad(False);

        this.player = Player();

        this.walls = [
            Boundary(
                Vector(), Vector(RESOLUTION.x)
            ),
            Boundary(
                Vector(RESOLUTION.x), RESOLUTION
            ),
            Boundary(
                RESOLUTION, Vector(0, RESOLUTION.y)
            ),
            Boundary(
                Vector(0, RESOLUTION.y), Vector()
            )
        ];

        this.__resetPart();

        mixer.init();
        this.__hitSound   = mixer.Sound(os.path.join(HOME_DIR, "sounds", "hit.mp3"));
        this.__deathSound = mixer.Sound(os.path.join(HOME_DIR, "sounds", "death.mp3"));
        this.__bonusSound = mixer.Sound(os.path.join(HOME_DIR, "sounds", "bonus.mp3"));

        this.__lightning0 = graphics.loadImage(
            os.path.join(HOME_DIR, "lightning.png"),
            LIGHTNING_SIZE_VEC
        );

        this.__lightning1 = this.__lightning0.copy();
        this.__lightning0.fill(FG, special_flags = BLEND_ADD);
        this.__lightning1.fill(BG, special_flags = BLEND_ADD);
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

        this.__sprintAmt = 0;

        this.__resetCustomPads();

        this.__sprintCooldown = SPRINT_COOLDOWN;
        this.__hitCooldown    = HIT_COOLDOWN;
    }

    new method __reset() {
        this.__resetPart();
        this.player.rainbowOff();
        this.leftPad.reset();
        this.rightPad.reset();

        this.__playerSprintOff();
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

    new method __playerSprintOn() {
        if this.__sprintAmt > 0 and this.__sprintCooldown >= SPRINT_COOLDOWN {
            this.__sprintCooldown = 0;

            this.player.sprintOn();
            this.__alphaChange = SPRINT_ALPHA_CHANGE;
        }
    }

    new method __playerSprintOff() {
        this.player.sprintOff();
        this.__alphaChange = ALPHA_CHANGE;
        graphics.resetCenter();
    }

    new method __move(event) {
        global DEBUG_MODE;

        if (not this.player.sprinting) and not this.player.explosion.isAlive() {
            if event.key in SPRINT_KEYS {
                if this.player.playing {
                    this.__playerSprintOn();
                }
            } elif event.key in KEYS {
                this.player.jump();
            }
        }

        if event.key == K_F3 {
            !DEBUG_MODE;
        }
    }

    new method __moveClick(event) {
        if (not this.player.sprinting) and not this.player.explosion.isAlive() {
            match event.button {
                case 3 {
                    if this.player.playing {
                        this.__playerSprintOn();
                    }
                }
                case 1 {
                    this.player.jump();
                }
            }
        }
    }

    new method __release(event) {
        if this.player.playing and this.player.sprinting {
            if event.key in SPRINT_KEYS {
                this.__playerSprintOff();
            }
        }
    }

    new method __releaseClick(event) {
        if this.player.playing and this.player.sprinting {
            if event.button == 3 {
                this.__playerSprintOff();
            }
        }
    }

    new method __invert() {
        if this.__hitCooldown >= HIT_COOLDOWN {
            this.__hitCooldown = 0;

            mixer.Sound.play(this.__hitSound);
            this.player.invert();
        }
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
            graphics.line(
                SPRINT_LINE_POS,
                Vector(
                    SPRINT_LINE_POS.x + Utils.translate(
                    this.__sprintAmt,
                    0, SPRINT_MAX_VALUE,
                    2, SPRINT_LINE_LENGTH
                    ),
                    SPRINT_LINE_POS.y
                ),
                FG, SPRINT_LINE_WIDTH
            );

            if this.__color and RAYCASTING {
                new dynamic walls = this.walls.copy();

                if this.customLeftPad is not None and this.customRightPad is not None {
                    walls += this.customLeftPad.boundaries + this.customRightPad.boundaries;
                } else {
                    walls += this.leftPad.boundaries + this.rightPad.boundaries;
                }
                
                for obstacle in this.obstacles {
                    walls += obstacle.boundaries;
                }

                this.player.look(walls);
            }   

            if this.__color {
                graphics.blitSurf(this.__lightning0, LIGHTNING_POS);
            } else {
                graphics.blitSurf(this.__lightning1, LIGHTNING_POS);
            }

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

            if not this.player.sprinting {
                if this.__sprintAmt < SPRINT_MAX_VALUE {
                    this.__sprintAmt += SPRINT_CHARGE_DELTA;
                }
            } else {
                graphics.translate(Vector(randint(-SHAKE, SHAKE), randint(-SHAKE, SHAKE)));

                if this.__sprintAmt > 0 {
                    this.__sprintAmt -= SPRINT_USE_DELTA;
                } else {
                    this.__playerSprintOff();
                }
            }

            this.__sprintCooldown++;
            this.__hitCooldown++;
        } elif not this.player.explosion.isAlive() {
            graphics.simpleText("JUMP TO START", START_TEXT_POS, FG, True, True);
        }

        this.player.update();

        this.__dayCounter++;
        if this.__dayCounter == DAY_CYCLE {
            this.__dayCounter = 0;
            unchecked: BG, FG = FG, BG;

            !this.__color;
        }

        if DEBUG_MODE {
            graphics.fastRectangle(OBSTACLE_SAFE_ZONE, RESOLUTION - OBSTACLE_SAFE_ZONE * 2, SAFE_ZONE_COLOR, DEBUG_LINES_WIDTH);
        }
    }

    new method run() {
        graphics.event(KEYDOWN)(this.__move);
        graphics.event(KEYUP)(this.__release);
        graphics.event(MOUSEBUTTONDOWN)(this.__moveClick);
        graphics.event(MOUSEBUTTONUP)(this.__releaseClick);
        graphics.update(this.update);

        graphics.fill(BG);
        graphics.run(drawBackground = False);
    }

    new method __benchmark(step, spacing) {
        new function benchmark() {
            global RAYCASTING, RAYS_QTY;

            graphics.simpleText(str(this.__currFrame), Vector(CENTER.x, 5 * (CENTER.y // 3)), FG, True, True);
            graphics.fillAlpha(BG, this.__alphaChange);
            graphics.line(
                SPRINT_LINE_POS,
                Vector(
                    SPRINT_LINE_POS.x + Utils.translate(
                    this.__sprintAmt,
                    0, SPRINT_MAX_VALUE,
                    2, SPRINT_LINE_LENGTH
                    ),
                    SPRINT_LINE_POS.y
                ),
                FG, SPRINT_LINE_WIDTH
            );

            if RAYCASTING {
                new dynamic walls = this.walls.copy();

                walls += this.leftPad.boundaries + this.rightPad.boundaries;

                if this.leftFlying is not None and this.rightFlying is not None {
                    walls += this.leftFlying.boundaries + this.rightFlying.boundaries;
                }
                
                for obstacle in this.obstacles {
                    walls += obstacle.boundaries;
                }

                IO.out(
                    this.player.pos,
                    IO.endl,
                    this.player.rays[0].pos,
                    IO.endl,
                    "===="
                );

                this.player.look(walls);
            }   

            graphics.blitSurf(this.__lightning0, LIGHTNING_POS);

            this.leftPad.update();
            this.rightPad.update();
            this.bonus.update();

            for obstacle in this.obstacles {
                obstacle.update();
            }

            if this.__currFrame % FLYING_CHANGE_EACH == 0 {
                this.leftFlying  = FlyingObstacle(Vector(step.x, step.y * 7), FlyingObstacle.LEFT);
                this.rightFlying = FlyingObstacle(step * 7, FlyingObstacle.RIGHT);
            }

            this.leftFlying.update();
            this.rightFlying.update(); 

            this.player.update();

            if this.player.pos.x >= RESOLUTION.x {
                this.player.pos.y += step.y;
                this.player.pos.x = 0;

                if this.player.pos.y >= RESOLUTION.y {
                    this.player.pos.y = step.y - spacing;
                }
            }

            this.__sprintAmt++;
            if this.__sprintAmt == SPRINT_MAX_VALUE {
                this.__sprintAmt = 0;
            }

            this.__fps += graphics.getFps();

            this.__currFrame++;
            if this.__currFrame == BENCH_FRAMES {
                this.__currFrame = 0;
                new dynamic fps = this.__fps / BENCH_FRAMES;
                this.__fps = 0;

                if FRAMERATE <= fps <= FRAMERATE + 5 or not RAYCASTING {
                    new dynamic settings;
                    with open(os.path.join(HOME_DIR, "settings.json"), "w") as settings {
                        settings.write(json.dumps({
                            "framerate":  FRAMERATE,
                            "raycasting": RAYCASTING,
                            "rays":       RAYS_QTY
                        }));
                    }
                    
                    quit;
                } elif fps > FRAMERATE and RAYCASTING {
                    this.__minRays = RAYS_QTY;
                    RAYS_QTY = (RAYS_QTY + this.__maxRays) // 2;
                    this.player.resetRays();
                } elif RAYS_QTY <= MIN_RAYS + 1 {
                    RAYCASTING = False;
                } else {
                    this.__maxRays = RAYS_QTY;
                    RAYS_QTY = (RAYS_QTY + this.__minRays) // 2;
                    this.player.resetRays();
                }
            } 
        }

        return benchmark;
    }

    new method benchmark() {
        this.__fps       = 0;
        this.__currFrame = 0;

        this.__maxRays = MAX_RAYS;
        this.__minRays = MIN_RAYS;

        new dynamic origStep = Vector(RESOLUTION.x // 8, RESOLUTION.y // 8),
                    step     = origStep.copy(),
                    pos      = origStep.copy(),
                    spacing  = step.y // 2;
        origStep.x *= 7;
        origStep.y *= 6;

        this.obstacles = [];
        while not pos == origStep {
            this.obstacles.append(Obstacle(pos.copy()));
            this.obstacles[-1].lifeSpan = -1;
            pos.x += step.x;

            if pos.x >= origStep.x {
                pos.x  = step.x;
                pos.y += step.y;

                if pos.y >= origStep.y {
                    break;
                }
            }
        }

        this.bonus = Bonus(Vector(randint(0, RESOLUTION.x), randint(0, RESOLUTION.y)));

        this.player.pos        = Vector(0, step.y - spacing);
        this.player.velocity.x = 1;
        this.player.playing    = True;
        this.player.sprinting  = True;

        this.leftFlying  = None;
        this.rightFlying = None;
        
        graphics.framerate = None;
        graphics.update(this.__benchmark(step, spacing));
        graphics.fill(BG);
        graphics.run(drawBackground = False);
    }
}

main {
    with open(os.path.join(HOME_DIR, "settings.json"), "r") as settings {
        new dynamic sets = json.load(settings);

        FRAMERATE  = sets["framerate"];
        RAYCASTING = sets["raycasting"];
        RAYS_QTY   = sets["rays"];
    }

    if "--bench" in sys.argv {
        Game().benchmark();
    } else {
        Game().run();
    }
}
