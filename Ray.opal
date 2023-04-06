new record Boundary(a, b);

new class Ray {
    new method __init__(pos, dir) {
        this.pos = pos;
        this.dir = Vector().fromAngle(dir);
        this.angle = dir;
    }
    
    new method cast(wall) {
        new dynamic x1 = wall.a.x, 
                    y1 = wall.a.y,
                    x2 = wall.b.x,
                    y2 = wall.b.y,

                    x3 = this.pos.x,
                    y3 = this.pos.y,
                    x4 = this.pos.x + this.dir.x,
                    y4 = this.pos.y + this.dir.y;

        static:
        new float den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

        if den == 0 {
            return None;
        }

        static:
        new float t =  ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / den,
                  u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / den;

        if 0 < t < 1 and u > 0 {
            return Vector(
                x1 + t * (x2 - x1),
                y1 + t * (y2 - y1)
            );
        } else {
            return None;
        }
    }
}