/// World dimensions and gameplay tuning (world pixels).
const double kWorldH = 800.0;
const double kTile = 64.0;
const double kGravity = 2200.0;
const double kJumpVel = 900.0;
const double kRunSpeed = 200.0;
const int kMaxLevel = 100;

enum TileType { ground, platform, brick, breakable, pipe, water }

enum EnemyType { mushroom, turtle, fly }

enum PowerUpType { coin, star }
