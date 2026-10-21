================================================================
  TINY QUESTERS  —  Free Warrior (Body-Only / Modular)
  A free sample from "Tiny Questers — Complete Pixel RPG
  Asset Pack" by Bobddadoo  (https://bobddadoo.itch.io)
================================================================

Thanks for downloading! This is the MODULAR version of the
top-down warrior: the body is animated WITHOUT any sword or
shield baked in, and the weapon / shield / hand pieces are
shipped SEPARATELY in items/ so you can layer them on top in
code and swap, recolor, or remove gear at runtime.

Free for personal and commercial projects.

Use it to:
  - Equip / unequip weapons and shields on the fly.
  - Build many looks from one body (different swords, shields).
  - Drive the held items independently of the body animation.

This Warrior is a free sample from the upcoming full pack:

      TINY QUESTERS  —  Complete Pixel RPG Asset Pack
      8 RPG classes, each with the same complete animation set:
        Knight  ·  Priestess  ·  Bard       ·  Dark Mage
        Warrior ·  Mage       ·  Rogue      ·  Elf Archer
      (+ VFX, launching on itch.io and the Unity Asset Store)

Follow Bobddadoo on itch.io to be notified the moment the full
pack drops — and to get launch-week discounts.


----------------------------------------------------------------
  FOLDER STRUCTURE
----------------------------------------------------------------

warrior_bodyonly_free/
  README.txt              ... this file
  LICENSE.txt             ... license terms (please read)

  items/                  ... separate gear pieces to layer on
                              the body (64 x 64, SAME pivot as
                              the body — drop them straight on
                              top, no offset needed)
    hand1.png, hand2.png        ... bare hand / fist pieces
    shield1.png ~ shield4.png   ... shield, 4 facings
    sword1.png  ~ sword4.png    ... sword, 4 rotations
                                    (up / left / down / right)

  png/
    single/               ... individual PNG frames
                              idle / walk / hit ... 64  x 49
                              die / die_no_shadow . 73  x 49
                              attack_*            . 128 x 128
      idle/
        down/             ...   down1.png   ~ down5.png
        up/               ...   up1.png     ~ up5.png
      walk/
        down/             ...   down1.png   ~ down4.png
        up/               ...   up1.png     ~ up4.png
        left/             ...   left1.png   ~ left4.png
        right/            ...   right1.png  ~ right4.png
      hit/                ...   hit1.png    ~ hit3.png
      die/                ...   die1.png    ~ die10.png  (with shadow)
      die_no_shadow/      ...   die_no_shadow1.png ~ die_no_shadow10.png
      attack_down/        ...   attack_down1.png   ~ attack_down20.png
      attack_up/          ...   attack_up1.png     ~ attack_up20.png
      attack_left/        ...   attack_left1.png   ~ attack_left18.png
      attack_right/       ...   attack_right1.png  ~ attack_right18.png
    atlas/                ... horizontal sprite sheets (single PNG per animation)
      idle_down.png             ...   5 frames   (320  x 49)
      idle_up.png               ...   5 frames   (320  x 49)
      walk_down.png             ...   4 frames   (256  x 49)
      walk_up.png               ...   4 frames   (256  x 49)
      walk_left.png             ...   4 frames   (256  x 49)
      walk_right.png            ...   4 frames   (256  x 49)
      hit.png                   ...   3 frames   (192  x 49)
      die.png                   ...   10 frames  (730  x 49)   [73 px per frame]
      die_no_shadow.png         ...   10 frames  (730  x 49)   [73 px per frame]
      attack_down.png           ...   20 frames  (2048 x 256) [16 per row, 2 rows]
      attack_up.png             ...   20 frames  (2048 x 256) [16 per row, 2 rows]
      attack_left.png           ...   18 frames  (2048 x 256) [16 per row, 2 rows]
      attack_right.png          ...   18 frames  (2048 x 256) [16 per row, 2 rows]

    single_pot/           ... power-of-two padded versions of single/
                              (original art placed at top-left (0,0),
                              transparent padding on the right/bottom —
                              pivot and per-frame coordinates unchanged)
                              idle / walk / hit ... 64  x 64
                              die / die_no_shadow . 128 x 64
                              attack_*            . 128 x 128 (already POT, identical to single/)
      idle/{down,up}/, walk/{down,up,left,right}/, hit/, die/, die_no_shadow/,
      attack_down/, attack_up/, attack_left/, attack_right/
        (same filenames as single/)
    atlas_pot/            ... power-of-two padded versions of atlas/
                              (original sheet placed at top-left (0,0),
                              transparent padding on the right/bottom —
                              slice with the SAME pixel sizes as atlas/)
      idle_down.png             ...   5 frames   (512  x 64)
      idle_up.png               ...   5 frames   (512  x 64)
      walk_down.png             ...   4 frames   (256  x 64)
      walk_up.png               ...   4 frames   (256  x 64)
      walk_left.png             ...   4 frames   (256  x 64)
      walk_right.png            ...   4 frames   (256  x 64)
      hit.png                   ...   3 frames   (256  x 64)
      die.png                   ...   10 frames  (1024 x 64)  [73 px per frame]
      die_no_shadow.png         ...   10 frames  (1024 x 64)  [73 px per frame]
      attack_down.png           ...   20 frames  (2048 x 256) [identical to atlas/, already POT]
      attack_up.png             ...   20 frames  (2048 x 256)
      attack_left.png           ...   18 frames  (2048 x 256)
      attack_right.png          ...   18 frames  (2048 x 256)

  gif/                    ... preview GIFs, transparent background
    1x/                   ... original size
                              idle / walk / hit ... 64  x 49
                              die / die_no_shadow . 73  x 49
                              attack_*            . 128 x 128
      idle_down.gif, idle_up.gif, walk_down.gif, walk_up.gif, walk_left.gif,
      walk_right.gif, hit.gif, die.gif, die_no_shadow.gif,
      attack_down.gif, attack_up.gif, attack_left.gif, attack_right.gif
      shield.gif, sword.gif   ... item previews — the 4 facings /
                                  rotations cycled as one looping
                                  GIF (64 x 64, transparent bg)
    5x/                   ... 5x upscaled, nearest-neighbor
                              idle / walk / hit ... 320 x 245
                              die / die_no_shadow . 365 x 245
                              attack_*            . 640 x 640
                              shield / sword      . 320 x 320
      (same filenames as 1x/)


----------------------------------------------------------------
  ITEMS — HOW THE MODULAR PIECES WORK
----------------------------------------------------------------

  The body animations contain NO weapon and NO shield. The gear
  lives in items/ as standalone 64 x 64 sprites that share the
  body's pivot, so you composite them as a second sprite layer:

      [ shadow / ground ]
      [ body animation  ]   <- png/single or png/atlas
      [ shield / sword  ]   <- items/  (drawn above or below
                                the body depending on facing)

  Because every item sits on the same 64 x 64 canvas and pivot
  as the body, you can parent the item sprite directly to the
  character with a zero offset and it lines up with the hand.

    hand1 / hand2       Bare hand / fist pieces — use these when
                        the warrior is unarmed, or to redraw a
                        hand on top of a held item.
    shield1 ~ shield4   The shield seen from 4 facings — pick the
                        one that matches the direction the body
                        is currently facing (down / side / up).
    sword1 ~ sword4     The sword in 4 rotations (up / left /
                        down / right) — pick the one that matches
                        the attack/facing direction.

  Tip: choose the item frame from your character's current
  facing state, and flip horizontally for the opposite side if
  you only want to store one side. Sort the item layer in front
  of the body for "down/side" facings and behind it for "up".


----------------------------------------------------------------
  ANIMATION FRAMES
----------------------------------------------------------------

  Idle Down ....... 5 frames
  Idle Up ......... 5 frames
  Walk Down ....... 4 frames
  Walk Up ......... 4 frames
  Walk Left ....... 4 frames
  Walk Right ...... 4 frames
  Hit ............. 3 frames
  Die ............. 10 frames  (+ no-shadow variant)
  Attack Down ..... 20 frames
  Attack Up ....... 20 frames
  Attack Left ..... 18 frames
  Attack Right .... 18 frames

  All frames: transparent background (PNG). Idle / walk / hit
  use a consistent 64 x 49 size and pivot. Die / die_no_shadow
  use 73 x 49 (a slightly wider canvas for the fall). Attack
  animations use 128 x 128 so the full swing arc fits inside the
  frame. The pivot (feet center) is consistent across every body
  animation AND every item, so swapping clips or gear at runtime
  won't shift the character.

  This is the BODY-ONLY / modular build — the attacks here are
  the moving (forward-step) versions, one per direction, with no
  weapon baked in. Add your chosen sword from items/ on top to
  arm the swing. (The all-in-one warrior_free pack ships the
  sword & shield baked into every frame, plus _stay attack
  variants, if you'd rather not composite gear yourself.)

  Both individual frames (png/single/) and horizontal sprite
  sheets (png/atlas/) are included — pick whichever your engine
  prefers. Power-of-two padded copies are also provided in
  png/single_pot/ and png/atlas_pot/ for engines / GPUs that
  require POT textures (mobile, older OpenGL ES, some compressed
  formats). The original art sits at top-left (0,0) with
  transparent padding on the right/bottom, so per-frame pixel
  sizes and the pivot are identical to the non-POT versions.
  Attack art is already 128 x 128 (POT) and 2048 x 256 (POT) so
  the _pot copies are byte-identical to the non-POT ones.

  Engine-agnostic — works in Unity, Godot, GameMaker, Construct,
  RPG Maker, and more.

  GIF previews of every animation are in gif/ (1x and 5x), with
  a transparent background, for quick visual reference and for
  store/itch.io page screenshots.


----------------------------------------------------------------
  HOW TO USE
----------------------------------------------------------------

  Unity:
    1. Drop png/single/ or png/atlas/ into Assets/.
    2. Set Texture Type = Sprite (2D and UI).
    3. Set Filter Mode = Point (no filter) and Compression = None
       to keep the pixel-art look crisp.
    4a. Single frames: select all PNGs of one animation and drag
        into the scene to auto-create an Animation clip.
    4b. Atlas: set Sprite Mode = Multiple, open Sprite Editor,
        Slice -> Grid By Cell Size.
          Idle / walk / hit  ->  Pixel Size 64  x 49
          Die / die_no_shadow -> Pixel Size 73  x 49
          Attack_*           ->  Pixel Size 128 x 128
            (2048 x 256 sheet, 16 frames in row 0, remaining
             frames in row 1 — Unity will pick them up in order)
        For atlas_pot/ use the SAME pixel sizes — extra empty
        cells at the right edge are transparent and can be left
        unused or deleted in the Sprite Editor.
    5. MODULAR GEAR: add a child SpriteRenderer for the held
       item, import items/ as Sprites, and set its sprite to the
       sword/shield frame that matches the body's current facing.
       Same pivot = zero local offset. Use Sorting Order to put
       the item in front of (down/side) or behind (up) the body.

  Godot:
    1. Import png/single/ (or atlas/) and items/ into your project.
    2. In the Import dock set Filter = Off and Mipmaps = Off.
    3. Use AnimatedSprite2D / AnimationPlayer for the body, and a
       second Sprite2D as a child for the equipped item; swap its
       texture per facing and set z_index to sort it.

  General:
    - Loop: idle, walk_*.   One-shot: hit, die, attack_*.
    - For "left", you can either use the included left frames or
      flip the right frames horizontally — both work (same for
      attack_left / attack_right, and for the item pieces).
    - Attack timing: ~6.67 fps (matches all other animations).
      20-frame attacks run ~3.0s, 18-frame attacks run ~2.7s.


----------------------------------------------------------------
  LICENSE — SHORT VERSION  (full text in LICENSE.txt)
----------------------------------------------------------------

  [OK] Free for personal and commercial projects
  [OK] Credit appreciated but not required
  [OK] Modify and edit freely to fit your game
  [NO] Do not resell or redistribute the assets on their own,
       or as part of another asset pack
  [NO] Do not use these assets to train AI / machine-learning
       models

  In short: use it in your games as much as you like — just
  don't repackage and sell the art itself.


----------------------------------------------------------------
  COMING SOON  —  THE OTHER 7 CLASSES
----------------------------------------------------------------

  Warrior is 1 of 8 classes in "Tiny Questers — Complete Pixel
  RPG Asset Pack". The other 7 are on the way — each with the
  same complete animation set (idle, 4-way walk, hit, die,
  attacks) and the same pivot, so they drop straight into the
  same animator setup you build with this Warrior.

    Knight       — heavy-armored sword & shield, the tank
    Priestess    — holy support, healing & buffs
    Bard         — lute-armed traveler, party utility
    Dark Mage    — forbidden magic, shadow & curse attacks
    Mage         — staff-wielding spellcaster, ranged elemental
    Rogue        — hooded daggerman, fast and lethal
    Elf Archer   — bow-wielding ranger, long-range DPS

  The full bundle (+ VFX add-ons: slashes, sparks, magic bursts,
  death poofs) will launch on itch.io and on the Unity Asset
  Store. Follow Bobddadoo on itch.io to be notified the moment
  it drops — followers get launch-week discounts.


----------------------------------------------------------------
  FEEDBACK & THE FULL PACK
----------------------------------------------------------------

  Spotted a misaligned frame or want a specific animation in
  the full set? Leave a comment on the itch.io page — early
  feedback directly shapes "Tiny Questers — Complete Pixel
  RPG Asset Pack".

  The full 8-class pack (plus VFX) will launch on itch.io and
  on the Unity Asset Store. Follow Bobddadoo on itch.io to get
  launch-week discounts.

  Thanks for checking it out — happy dev!  :)


================================================================
  (c) Bobddadoo — https://bobddadoo.itch.io
================================================================
