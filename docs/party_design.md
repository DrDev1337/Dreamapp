# Party-pivoten: Essence som 5-manna dungeon-crawler

**Beslut (2026-07-11):** Solohjälten ersätts av ett party om 5 hjältar, i stil med en
WoW-dungeongrupp. Handlingsekonomi: **varje levande hjälte agerar en gång per runda.**
Ren taktik – ingen tärnings-/dragslump i handlingarna. Byggdjupet kommer från
lagkompositionen (Slice & Dice-inspirationen), inte från slump.

## Kärnfantasin

Du leder fem gråa nollor (nivå 1-rekryter) ner i djupet. Genom valen du gör – vem som
får uppgraderingen, åt vilket håll – formas de till ett lag: tank, healer, damage.
Kombon är bygget. Essens-loopen (bär/riskera/banka, corpse-run, checkpoint-valet)
behålls oförändrad – partyt ersätter bara hjälten som farkost.

## Formation: fram/bak i stället för aggro

- 5 hjältar: **position 1–2 = frontrad, 3–5 = bakrad.**
- Melee-fiender kan bara slå frontraden (så länge någon där lever).
  Ranged/healer-fiender når alla. Det är vår "tank threat" – synlig och begriplig.
- **Taunt** (tank-förmåga) tvingar fiender att slå tanken oavsett rad.

## Strid

- Turordning per fart, hjältar och fiender interfolierade. Varje levande hjälte
  agerar exakt en gång per runda; UI:t markerar vems tur det är.
- Fiende-intentioner planeras vid rundstart och visar nu även **vilken hjälte**
  fienden tänker slå ("Attack Ylva ~7") – det taktiska pusslet.
- **Hjältedöd ≠ förlust:** en hjälte på 0 HP är utslagen (resten av striden och
  vidare tills checkpoint, som väcker upp och helar alla). Runnen förloras först
  vid **full wipe** – då gäller Essens-högen som vanligt.
- **Auto-mål för stödförmågor:** heal/sköld går automatiskt till mest skadad
  levande hjälte, revive till första fallna. Spelaren väljer bara fiendemål –
  minimal friktion på mobil (kan göras valbart senare).

## Roller och klassning (4 axlar)

Alla hjältar startar med enbart basattack. Vid party-level-up väljs **en**
uppgradering: 3 alternativ, kopplade till tre olika hjältar. Tre val åt samma håll
på samma hjälte låser klassidentitet + signaturförmåga.

| Axel | Karaktär | Förmågor | Signatur |
|---|---|---|---|
| Tank | uthållighet, kontroll | Taunt, Shield Bash (stun), Fortify | Bulwark (sköld + mass-taunt) |
| Healer | uppehälle | Mend, Radiance (grupp-heal), Smite | Resurrect (väcker fallen) |
| Mage | AoE/magisk skada | Firebolt, Frost Nova, Arcane Shield | Meteor |
| Rogue | single-target burst | Backstab, Poison Blade, Evasion | Shadow Dance |

- XP är gemensam (party-level). Djupgrindarna gäller party-level.
- Loot är per hjälte (vapen/rustning/smycke); vid drop väljs bärare.
- Hubbens permanenta uppgraderingar gäller hela laget (lägre tal per rank).

## Medvetna förenklingar i första versionen

- Formationen är fast (1–2 fram) – flytt av hjältar mellan rader är nästa steg.
- Stödförmågor auto-targetar (se ovan).
- Rekryterna är identiska vid start – olika rekryttyper/traits är en framtida
  Essens-sänka.

## Sparformat

SAVE_VERSION höjs till 2. Äldre saves (solo) kasseras vid laddning – acceptabelt
före release.
