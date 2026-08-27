module lublinsql::position;

struct Position {
    sz index;
    sz line;
    sz column;
}

struct PositionVector {
    Position start;
    Position end;
}