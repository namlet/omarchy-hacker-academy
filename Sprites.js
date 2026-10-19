// Pixel art, drawn as text so it is easy to edit and review: each character is one
// pixel, "." is see-through. Every sprite has its own 8-bit colors (pal), and for the
// "match theme" setting, which letters follow a theme color instead (themed: the
// theme role, and how much lighter or darker). Theme.spriteColors picks between them.
// See them all with `make preview`.

var SPRITES = {
  // Goofy robot sidekick: antenna, bolt ears, eyes that don't agree, a toothy grin.
  bolt: {
    rows: [
      "...........YY...........",
      "..........YHYy..........",
      "..........yYYy..........",
      "...........KK...........",
      "...........KK...........",
      "....KKKKKKKKKKKKKKKK....",
      "...KHHBBBBBBBBBBBBBBK...",
      "...KHBBBBBBBBBBBBBBbK...",
      "...KBBKKKKKBBBBBBBBbK...",
      ".YyKBKWWWWWKBKKKKBBbKyY.",
      "YYyKBKWWKKWKBKWWKBBbKyYY",
      "YYyKBKWWKKWKBKWKKBBbKyYY",
      ".YyKBKWWWWWKBKKKKBBbKyY.",
      "...KBBKKKKKBBBBBBRRbK...",
      "...KBBBBBBBBBBBBBRRbK...",
      "...KBBKKKKKKKKKKKKBbK...",
      "...KBBKTTTTTTTTTTKBbK...",
      "...KBBKMMMMRRMMMMKBbK...",
      "...KBBBKKKKKKKKKKBBbK...",
      "...KbBBBBBBBBBBBBBbbK...",
      "....KKKKKKKKKKKKKKKK....",
      "..........KbbK..........",
      "...KKKKKKKKKKKKKKKKKK...",
      "...KBBBBBBBYYBBBBBBBK..."
    ],
    pal: {"K": "#0e0e14", "B": "#7dcfff", "b": "#3d8fb3", "H": "#d4f3ff", "W": "#eef2ff", "Y": "#e0af68", "y": "#9a6b2e", "R": "#f7768e", "M": "#1a1b26", "T": "#eef2ff"},
    themed: {"B": ["accent", 0], "b": ["accent", -0.4], "H": ["accent", 0.6], "Y": ["rank", 0], "y": ["rank", -0.4], "R": ["danger", 0]}
  },
  // Calm, kind, a little dry: white hat, dark glasses, a small smirk.
  mentor: {
    rows: [
      "........................",
      ".........KKKKKK.........",
      "........KWWWWWSK........",
      ".......KWWWWWWWSK.......",
      ".......KAAAAAAAAK.......",
      "..KWWWWWWWWWWWWWWWWWSK..",
      "...KKKKKKKKKKKKKKKKKK...",
      ".....KFFFFFFFFFFFFK.....",
      ".....KKKKKKKKKKKKKK.....",
      ".....KKHGGGKKHGGGKK.....",
      ".....KFKKKKFFKKKKFK.....",
      ".....KFFFFFffFFFFFK.....",
      ".....KFFFFFFFFFFFFK.....",
      ".....KFFFFFFFFKFFFK.....",
      ".....KFFFFKKKKKFFFK.....",
      "......KFFFFFFFFFFK......",
      ".......KKFFFFFFKK.......",
      "........KKfFFfKK........",
      "....KKKKCCWWWWCCKKKK....",
      "...KCCCCCWWAAWWCCCCCK...",
      "..KCCCCCCCWAAWCCCCCCCK..",
      "..KCCCCCCCCAACCCCCCCCK..",
      "..KCcCCCCCCAACCCCCCcCK..",
      "..KCcCCCCCCCCCCCCCCcCK.."
    ],
    pal: {"K": "#0e0e14", "W": "#eef2ff", "S": "#a9b1d6", "A": "#7aa2f7", "F": "#d9a77a", "f": "#a8754d", "G": "#1a1b26", "H": "#7dcfff", "C": "#3b4261", "c": "#2a2e42"},
    themed: {"A": ["accent", 0], "H": ["accent", 0.3]}
  },
  // What leaks out when Bolt's antenna sparks.
  bug: {
    rows: [
      "...K........K...",
      "....K......K....",
      ".....KKKKKK.....",
      "....KGWGGWGK....",
      "....KGGGGGGK....",
      ".K.KHRRKKRRRK.K.",
      "..KKRRRKKRRrKK..",
      "...KRDRKKRDrK...",
      ".KKKRRRKKRRrKKK.",
      "...KRRDKKDRrK...",
      "..KKRRRKKRRrKK..",
      ".K.KrRRKKRrrK.K.",
      "....KrrKKrrK....",
      ".....KKKKKK.....",
      "................",
      "................"
    ],
    pal: {"K": "#0e0e14", "G": "#2f3549", "g": "#6b7394", "W": "#eef2ff", "R": "#f7768e", "H": "#ffb3c1", "r": "#b3475c", "D": "#7a2a3a"},
    themed: {"R": ["danger", 0], "H": ["danger", 0.5], "r": ["danger", -0.3], "D": ["danger", -0.55]}
  },
  // The bug that only answers a right-click wears a bandit mask.
  sneakyBug: {
    rows: [
      "...K........K...",
      "....K......K....",
      ".....KggggK.....",
      "...KKKWKKWKKK...",
      "....KggggggK....",
      ".K.KHRRKKRRRK.K.",
      "..KKRRRKKRRrKK..",
      "...KRDRKKRDrK...",
      ".KKKRRRKKRRrKKK.",
      "...KRRDKKDRrK...",
      "..KKRRRKKRRrKK..",
      ".K.KrRRKKRrrK.K.",
      "....KrrKKrrK....",
      ".....KKKKKK.....",
      "................",
      "................"
    ],
    pal: {"K": "#0e0e14", "G": "#2f3549", "g": "#6b7394", "W": "#eef2ff", "R": "#9d7cd8", "H": "#d0bcff", "r": "#6a4fa8", "D": "#3f2f66"},
    themed: {"R": ["magenta", 0], "H": ["magenta", 0.5], "r": ["magenta", -0.3], "D": ["magenta", -0.55]}
  },
  // The Glitch, from mission 4 on: scrambles things, never scary.
  glitch: {
    rows: [
      "................",
      ".....KKKKKK.....",
      "...KKMMMMMMKK...",
      "..KMMWWMMWWMMK..",
      "..KMMWKMMWKMMK..",
      "KKKKCCCCMMMMMK..",
      "KCCCCCKMMMMMMK..",
      "..KMMKMKMKMKMK..",
      "..KMMMMMMMMMMKKK",
      "....KMMMMMMCCCCK",
      "..KMMMMMMMMMMKKK",
      "..KMMKMMMMKMMK..",
      "..KMK.KMMK.KMK..",
      "...K...KK...K...",
      "................",
      "................"
    ],
    pal: {"K": "#0e0e14", "M": "#bb9af7", "W": "#eef2ff", "C": "#0db9d7"},
    themed: {"M": ["magenta", 0], "C": ["cyan", 0]}
  },
  // Glass jar with a lid; the inside shows the caught bug.
  jar: {
    rows: [
      "...KKKKKKKKKK...",
      "...KYYYYYYYYK...",
      "...KyyyyyyyyK...",
      "....KKKKKKKK....",
      "...KLggggggLK...",
      "..KLHgggggggLK..",
      "..KLHgggggggLK..",
      "..KLHgggggggLK..",
      "..KLggggggggLK..",
      "..KLggggggggLK..",
      "..KLggggggggLK..",
      "..KLggggggggLK..",
      "..KLggggggggLK..",
      "..KLggggggggLK..",
      "...KLLLLLLLLK...",
      "....KKKKKKKK...."
    ],
    pal: {"K": "#0e0e14", "Y": "#e0af68", "y": "#9a6b2e", "L": "#7dcfff", "g": "#1f3044", "H": "#d4f3ff"},
    themed: {"L": ["accent", 0.2], "H": ["accent", 0.7], "g": ["accent", -0.75], "Y": ["rank", 0], "y": ["rank", -0.4]}
  },
  // Rank badges: a shield with the rank's emblem.
  recruitBadge: {
    rows: [
      "...oooooooooooooo...",
      "..offffffffffffffo..",
      ".offffffffffffffffo.",
      "offffffffffffffffffo",
      "offffffffffffffffffo",
      "offffffffffffffffffo",
      "offffffffkkffffffffo",
      "offfffffkkkkfffffffo",
      "offffffkkffkkffffffo",
      "offfffkkffffkkfffffo",
      "offffffffkkffffffffo",
      "offfffffkkkkfffffffo",
      "offffffkkffkkffffffo",
      "offfffkkffffkkfffffo",
      ".offffffffffffffffo.",
      "..offffffffffffffo..",
      "...offffffffffffo...",
      "....offffffffffo....",
      ".....ooffffffoo.....",
      ".......ooffoo.......",
      ".........oo........."
    ],
    pal: {"o": "#c0caf5", "f": "#3d59a1", "k": "#e0af68", "w": "#eef2ff"},
    themed: {"f": ["accent", -0.45], "o": ["text", 0], "k": ["rank", 0]}
  },
  agentBadge: {
    rows: [
      "...oooooooooooooo...",
      "..offffffffffffffo..",
      ".offffffffffffffffo.",
      "offffffffffffffffffo",
      "offfffffkkkkfffffffo",
      "offffffkffffkffffffo",
      "offffffkffffkffffffo",
      "offffffkffffkffffffo",
      "offfffffkkkkfffffffo",
      "offffffffkkffffffffo",
      "offffffffkkffffffffo",
      "offffffffkkkkffffffo",
      "offffffffkkffffffffo",
      "offffffffkkkfffffffo",
      ".offfffffkkfffffffo.",
      "..offffffkkffffffo..",
      "...offffffffffffo...",
      "....offffffffffo....",
      ".....ooffffffoo.....",
      ".......ooffoo.......",
      ".........oo........."
    ],
    pal: {"o": "#c0caf5", "f": "#3d59a1", "k": "#e0af68", "w": "#eef2ff"},
    themed: {"f": ["accent", -0.45], "o": ["text", 0], "k": ["rank", 0]}
  },
  specialistBadge: {
    rows: [
      "...oooooooooooooo...",
      "..offffffffffffffo..",
      ".offffffffffffffffo.",
      "offffffffffffffffffo",
      "offffffffffffffffffo",
      "offffffffkkffffffffo",
      "offffffffkkffffffffo",
      "offfffffkkkkfffffffo",
      "offffkkkkkkkkkkffffo",
      "offfffkkkkkkkkfffffo",
      "offffffkkkkkkffffffo",
      "offffffkkkkkkffffffo",
      "offfffkkkffkkkfffffo",
      "offfffkkffffkkfffffo",
      ".offfkffffffffkfffo.",
      "..offffffffffffffo..",
      "...offffffffffffo...",
      "....offffffffffo....",
      ".....ooffffffoo.....",
      ".......ooffoo.......",
      ".........oo........."
    ],
    pal: {"o": "#c0caf5", "f": "#3d59a1", "k": "#e0af68", "w": "#eef2ff"},
    themed: {"f": ["accent", -0.45], "o": ["text", 0], "k": ["rank", 0]}
  },
  whiteHatBadge: {
    rows: [
      "...oooooooooooooo...",
      "..offffffffffffffo..",
      ".offffffffffffffffo.",
      "offffffffffffffffffo",
      "offffffffffffffffffo",
      "offffffffffffffffffo",
      "offffffffffffffffffo",
      "offfffffwwwwfffffffo",
      "offffffwwwwwwffffffo",
      "offffffwwwwwwffffffo",
      "offffffkkkkkkffffffo",
      "offffwwwwwwwwwwffffo",
      "offfffwwwwwwwwfffffo",
      "offffffffffffffffffo",
      ".offffffffffffffffo.",
      "..offffffffffffffo..",
      "...offffffffffffo...",
      "....offffffffffo....",
      ".....ooffffffoo.....",
      ".......ooffoo.......",
      ".........oo........."
    ],
    pal: {"o": "#c0caf5", "f": "#3d59a1", "k": "#e0af68", "w": "#eef2ff"},
    themed: {"f": ["accent", -0.45], "o": ["text", 0], "k": ["rank", 0]}
  }
}

// The badge for each rank, by rank name.
var BADGES = { Recruit: "recruitBadge", Agent: "agentBadge", Specialist: "specialistBadge", "White Hat": "whiteHatBadge" }

if (typeof module !== "undefined") {
  module.exports = { SPRITES: SPRITES, BADGES: BADGES }
}
