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
  agerar exakt en gång per runda – men spelaren väljer **fritt vilken hjälte**
  som tar varje partytur (tappa hjältepanelen). Fart avgör bara NÄR partyts
  turer infaller relativt fienderna. Statuseffekter på hjältar tickar vid
  rundstart; en stunnad hjälte förlorar rundans handling.
- Fiende-intentioner planeras vid rundstart och visar nu även **vilken hjälte**
  fienden tänker slå ("Attack Ylva ~7") – det taktiska pusslet.
- **Defend** (universell handling): halverar nästa träff OCH ger +3 mana.
  Tillsammans med stram passiv regen (1/handling) är det stridens ekonomi:
  ladda eller bränna, blocka intenten eller racea den (StS-block/S&D-pips).
- **Exposed** (combo-status via Backstab): målet tar +35% skada av alla i
  2 rundor – den fria handlingsordningen får payoff (öppna, sedan nuka).
- **Hjältedöd ≠ förlust:** en hjälte på 0 HP är utslagen (resten av striden och
  vidare tills checkpoint, som väcker upp och helar alla). Runnen förloras först
  vid **full wipe** – då gäller Essens-högen som vanligt.
- **Auto-mål för stödförmågor:** heal/sköld går automatiskt till mest skadad
  levande hjälte, revive till första fallna. Spelaren väljer bara fiendemål –
  minimal friktion på mobil (kan göras valbart senare).

## Roller och klassning (4 axlar)

Alla rekryter rullas med **en startförmåga** (en per axel täcks alltid; reroll ger
nya kombon) – det ger riktiga val redan i strid 1. Vid party-level-up väljs **en**
uppgradering: 3 alternativ, kopplade till tre olika hjältar. Två val åt samma håll
på samma hjälte låser klassidentitet + signaturförmåga (var tre, men simuleringen
visade att bara 2 av 5 klasser hann låsas på 100 runs – combon uppstod aldrig).

8 klassaxlar (D&D-inspirerade). Combo-statusar i **fetstil** – de är limmet
mellan klasserna och gör handlingsordningen till taktik:

| Axel | Karaktär | Förmågor | Signatur |
|---|---|---|---|
| Barbarian | raseri, AoE | Cleave, Rage (+60% skada), Reckless Swing | Rampage (AoE-svep) |
| Ranger | märkta mål | Hunter's Mark (**marked**: nästa träff +75%), Piercing Shot (ignorerar rustning), Volley | Deadeye |
| Warlock | förbannelser | Curse of Frailty (**weakened**: -30% fiendeskada), Life Drain (självläkning), Eldritch Blast | Doom (AoE + weakened) |
| Bard | partysånger | Cutting Words (**weakened**), Song of Rest (grupp-heal), Inspire (party +30% skada) | Grand Finale (party +50%) |
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

## Dungeonprogression

Spelet växer på djupet: **nya dungeons låses upp av boss-kills** (plus nivåkrav)
och blir svårare och svårare. Varje dungeon återanvänder samma 8-rumsstruktur men
med ett `depth_offset` som fortsätter fiende- och belöningskurvan där den förra
dungeonen slutade – The Sunken Crypt börjar alltså på "djup 9", The Ember Halls
på "djup 17". Nivågrindarna är dungeonspecifika och dödshögen är dungeonbunden:
tappar man sin Essens i kryptan måste man tillbaka dit för att hämta den.

| Dungeon | Tier | Kräver | Grindar (rum 4 / rum 7) |
|---|---|---|---|
| The Cave Depths | 1 | – | nivå 3 / 5 |
| The Sunken Crypt | 2 | nivå 6 + Cave-boss | nivå 8 / 10 |
| The Ember Halls | 3 | nivå 11 + Crypt-boss | nivå 13 / 15 |
