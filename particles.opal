new class Particle {
    new method __init__(pos) {
        this.pos          = pos;
        this.acceleration = Vector();

        this.velocity = Vector(uniform(-1, 1), uniform(-1, 1));
        this.velocity *= uniform(1, PARTICLE_MAX_INIT_VELOCITY);

        this.lifeSpan = 255;
        this.alive    = True;
    }

    new method applyForce(f) {
        this.acceleration += f;
    }

    new method update() {
        this.velocity *= PARTICLE_VELOCITY_MULTIPLIER;
        this.lifeSpan -= LIFESPAN_DECREASE * frameMultiplier;

        this.velocity += this.acceleration;
        this.pos      += this.velocity;

        this.acceleration *= 0;

        if this.pos.y >= RESOLUTION.y or this.pos.x < 0 or this.pos.x >= RESOLUTION.x {
            this.alive = False;
        }
    }

    new method isAlive() {
        return this.lifeSpan >= 0 and this.alive;
    }

    new method show() {
        graphics.circle(round(this.pos), PARTICLE_SIZE, FG, int(this.lifeSpan));
    }
}

new class Explosion {
    new method __init__(pos) {
        this.pos = pos;
        this.particles = [];
    }

    new method explode(pos = None) {
        if pos is not None {
            this.pos = pos;
        }

        repeat randint(MIN_PARTICLE_QTY, MAX_PARTICLE_QTY) {
            this.particles.append(Particle(this.pos));
        }
    }

    new method update() {
        for particle in this.particles {
            particle.update();
        }

        this.particles = [particle for particle in this.particles if particle.isAlive()];
    }

    new method isAlive() {
        return len(this.particles) > 0;
    }

    new method show() {
        for particle in this.particles {
            particle.show();
        }
    }
}