/// Default pricing data from docs/spec.md (Story 3). Seeded once on first launch.
typedef Anchor = (int supply, int retail);

const defaultAnchors = <Anchor>[
  (2000, 5000),
  (5000, 10000),
  (10000, 15000),
  (12000, 20000),
  (14000, 25000),
  (18000, 30000),
  (20000, 35000),
  (25000, 40000),
  (65000, 100000),
  (120000, 165000),
  (160000, 220000),
  (210000, 265000),
  (240000, 300000),
  (280000, 340000),
  (310000, 370000),
  (350000, 450000),
  (400000, 520000),
  (1000000, 1350000),
];

/// (minSupply, maxSupply or null for no limit, minMarginPct)
const defaultMarginThresholds = <(int, int?, double)>[
  (0, 65000, 30),
  (65000, 400000, 15),
  (400000, null, 20),
];
