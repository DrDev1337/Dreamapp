# Art direction: Essens

**Vald stil: minimal vektor-emblem.** Mörk fantasy byggd på siluett-ikonografi
(game-icons.net), typografi och färg – inte på illustrationer. Stilen är vald för att
den (1) ser avsiktlig och färdig ut redan utan artist, (2) skalar perfekt till alla
skärmar eftersom allt är vektorer, och (3) kan uppgraderas gradvis – enskilda ikoner
kan bytas mot riktiga illustrationer senare utan att helheten spricker.

## Byggstenar

**Typografi**
- Rubriker: **Cinzel 700** – klassisk versal-serif, ger dark fantasy-tyngd.
- Brödtext/knappar: **Alegreya Sans 400/700** – humanistisk, mycket läsbar på mobil.
- Titlar har alltid mörk textskugga; speltiteln får dessutom accent-glow.

**Färgpalett** (definieras i `src/ui/ui_kit.gd`, används aldrig hårdkodat på annat håll)

| Roll | Färg | Användning |
|---|---|---|
| Bakgrund | `#1a1621` | grundton, letterbox |
| Panel | `#262033` | kort, listor |
| Knapp | `#332b47` | sekundära handlingar |
| Accent | `#8c6ff0` (lila) | primära handlingar, emblem, avdelare |
| Essens | `#5fd4c4` (teal) | ALLT som rör Essens – kristallikon + siffror |
| HP | `#e05555` · Mana `#5580e0` · Varning `#e0a437` | barer och varningar |
| Rariteter | grå `#b8b8b8` / blå `#5fa8e0` / lila `#b45fe0` | loot |

**Ikonografi** (`assets/icons/`, game-icons.net, CC BY 3.0)
- Vita SVG-siluetter som tintas i kod → en ikon kan återanvändas i olika roller.
- Varje fiende har egen tint (`Icons.ENEMY_TINT`) som blir dess visuella identitet
  tills riktiga porträtt görs.
- Klassemblem: svärd (Kämpe), eldklot (Magiker), ninjamask (Skugga).
- Essens-kristallen är spelets signatursymbol – syns på titelskärm, hubb,
  checkpoint och victory.

**Djup och ljus**
- Skiktad bakgrund: grundfärg + radiellt accentsken uppifrån + vinjett (genereras
  i kod, `main.gd`).
- Paneler och knappar har mjuka skuggor; tryckt knapp tappar skuggan.

**Rörelse** (regler för juice)
- Skärmbyten tonar in (0,18 s). Aldrig hårda klipp.
- Allt som ändrar ett värde ska synas: HP-bars glider (0,3 s), skadesiffror flyger
  och bleknar, träffad fiende skakar, spelare som tar skada ger röd helskärmsblixt.
- Döda fiender dimmas till 35 % – de tas inte bort, slagfältet berättar historien.

## Uppgraderingsväg (när riktig art görs)

1. Fiende-siluetter → tecknade porträtt i samma ram och tint.
2. Biom-bakgrunder per djupsegment (1–3 grotta, 4–6 gravvalv, 7–8 hjärtkammare).
3. Partiklar: Essens-upphämtning, boss fas 2, checkpoint-eld.
4. Ikonerna behåller sina roller – bara filerna byts.
