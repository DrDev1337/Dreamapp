# Essens (arbetsnamn)

Turbaserat roguelite-RPG för mobil (iOS + Android). Portrait, enhandsspel, helt offline.

**Kärnkroken:** du samlar *Essens* från besegrade fiender. Vid varje checkpoint väljer du –
stanna och säkra allt, eller fortsätt djupare med allt osäkrat på spel. Dör du lämnas
allt i en hög på ditt djup. Nå dit i nästa run och du får tillbaka det. Dör du igen
först – då är det borta för alltid.

Byggt i **Godot 4.3** (mobile-renderer). Se `docs/user_stories.md` för hela specen.

## Komma igång

1. Installera [Godot 4.3+](https://godotengine.org/download) (standardversionen, inte .NET).
2. Öppna projektet: `godot project.godot` (eller importera mappen i Project Manager).
3. Kör med F5. Spelet är byggt för portrait 720×1280 och skalar med skärmen.

## Struktur

```
scenes/main.tscn      Enda scenen – allt UI byggs programmatiskt
src/autoload/game.gd  Global state: slots, save/load, run-livscykel   (autoload "Game")
src/autoload/ads.gd   Ads/IAP-stub – byts mot riktig SDK senare       (autoload "Ads")
src/core/             Ren spellogik utan UI-beroenden (testbar headless)
  balance.gd          ALLA balanssiffror – tuning sker bara här
  abilities.gd        Förmågekatalog (fighter/mage/rogue + signaturer)
  enemies.gd          Fiendekatalog: 5 typer + miniboss + boss, djupskalning
  combat.gd           Turbaserad stridsmotor, serialiserbar mitt i strid
  character.gd        Persistent karaktär: nivåer, klassval, utrustning, dödshög
  levelup.gd          Level-up-val som drar mot fighter/mage/rogue
  items.gd            Loot: 3 rariteter, episkt säkras direkt
  run_generator.gd    Procedurgenerering med fasta checkpoint/boss-regler
  run_state.gd        Pågående run: buren Essens, osäkrad loot, corpse run
  upgrades.gd         Permanenta uppgraderingar + tillfälliga boosts
src/ui/               En skärm per fil; main.gd är router och äger spelflödet
tests/run_tests.gd    Headless-tester för kärnlogiken
```

## Spela i webbläsaren (mobil)

Varje push till huvudbranchen bygger en HTML5-version via GitHub Actions och publicerar
den till GitHub Pages:

**https://drdev1337.github.io/Dreamapp/**

Webbexporten byggs utan trådstöd så att den fungerar i iOS Safari och på GitHub Pages
utan specialheaders. Save-filen ligger i webbläsarens lagring (IndexedDB) – rensar du
webbdata försvinner din progression. Webben är testkanalen; riktiga butiksbyggen
(Android/iOS) görs senare via Godots exportmallar.

## Tester och lint

```bash
# Kärnlogik-tester (kräver Godot i PATH)
godot --headless --import          # första gången: bygger klasscachen
godot --headless -s tests/run_tests.gd

# Syntax + stil (kräver: pip install gdtoolkit)
gdparse $(find src tests -name '*.gd')
gdlint src tests
gdformat --line-length 100 src tests
```

## Designbeslut (från specens öppna frågor)

1. **Boosts vid checkpoint** gäller resten av pågående run; köpta i hubben gäller nästa run.
2. **Checkpoints helar** till full HP/mana men respawnar inte fiender.
3. **Episk loot säkras direkt** vid upphämtning – att tappa den vore för hårt. Vanlig och
   sällsynt loot följer Essens-reglerna (tappas vid död, säkras vid checkpoint).
4. **Djupgränsen (US-1.3)** ligger vid checkpoints: rum 1–3 alltid, rum 4–6 kräver nivå 2,
   rum 7–8 kräver nivå 4. Så kan en run alltid avslutas snyggt vid en checkpoint.

## Status: MVP-skelett

Alla MVP-user-stories har en implementation (spellogik + UI-flöde). Medvetet kvar att göra:

- **Art & juice**: allt är färgpaneler + text. Sprites, animationer, haptik, ljud, hit-stop.
- **Riktig ads/IAP-SDK**: `src/autoload/ads.gd` är en stub med rätt anropspunkter.
- **Fiende-intentioner (US-3.4, V2)**, förråd (US-5.3), fler biomer/bossar (US-1.4, US-6.3),
  cloud save (US-11.3).
- **Balansering**: siffrorna i `balance.gd` är startvärden, inte speltestade.
