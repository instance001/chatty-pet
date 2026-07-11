class GridCoord {
  const GridCoord(this.x, this.y);

  final int x;
  final int y;

  int manhattanDistanceTo(GridCoord other) {
    return (x - other.x).abs() + (y - other.y).abs();
  }

  bool isWithin(int width, int height) {
    return x >= 0 && y >= 0 && x < width && y < height;
  }

  bool isAdjacentTo(GridCoord other) {
    return manhattanDistanceTo(other) == 1;
  }

  GridCoord stepToward(GridCoord target) {
    if (x != target.x) {
      return GridCoord(x + (target.x > x ? 1 : -1), y);
    }
    if (y != target.y) {
      return GridCoord(x, y + (target.y > y ? 1 : -1));
    }
    return this;
  }

  @override
  bool operator ==(Object other) {
    return other is GridCoord && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}
