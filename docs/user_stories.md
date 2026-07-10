# User Stories: Roguelite RPG (arbetsnamn: Essens)

**Version:** 0.1
**Plattform:** iOS + Android (Godot rekommenderas)
**Format:** Turbaserat, portrait, offline
**Monetisering:** Ads + engångsköp för ad-free

Prioritering: **[MVP]** = krävs för första spelbara version. **[V2]** = efter MVP.

---

## Epic 1: Kärnloop och runs

**US-1.1 [MVP]** Som spelare vill jag starta en run från en hubb så att jag snabbt kommer in i spelet.
- AC: Från hubben når jag "Starta run" med max 2 tryck.
- AC: En run på låg nivå tar 5-10 minuter.

**US-1.2 [MVP]** Som spelare vill jag röra mig genom en serie rum som blir svårare ju djupare jag går, så att risk och belöning ökar.
- AC: En run består av 6-8 rum i MVP.
- AC: Fiender och belöningar skalar med djupet.

**US-1.3 [MVP]** Som spelare vill jag på låg nivå bara kunna gå ett begränsat djup, så att progression känns meningsfull.
- AC: Djupgräns kopplad till karaktärsnivå eller besegrade bossar.
- AC: Tydlig indikation på varför jag inte kan gå djupare.

**US-1.4 [V2]** Som spelare vill jag låsa upp nya platser (grottor, biomer) när jag klarar bossar, så att världen växer med mig.
- AC: Minst en ny plats låses upp efter första bossen.

---

## Epic 2: Essens-systemet (kärnmekaniken)

**US-2.1 [MVP]** Som spelare vill jag samla Essens från besegrade fiender, så att jag har något att riskera och spendera.
- AC: Essens visas alltid i UI under run.
- AC: Fiender ger Essens skalat efter djup och svårighet.

**US-2.2 [MVP]** Som spelare vill jag vid checkpoints kunna välja mellan att avsluta runnen och spendera min Essens, eller fortsätta djupare med allt osäkrat, så att varje checkpoint är ett spännande beslut.
- AC: Checkpoint-skärm med två tydliga val: "Stanna och spendera" / "Fortsätt djupare".
- AC: Vid "fortsätt" följer all ospenderad Essens med och riskeras.

**US-2.3 [MVP]** Som spelare vill jag tappa all buren Essens när jag dör, så att risken känns på riktigt.
- AC: Vid död lämnas Essensen kvar på dödsplatsen (rummet/djupet).
- AC: Meta-progression och permanenta uppgraderingar påverkas inte.

**US-2.4 [MVP]** Som spelare vill jag kunna ta mig tillbaka till min dödsplats och plocka upp min tappade Essens, så att jag får en andra chans.
- AC: Dödsplatsen markeras tydligt (karta/indikator) i nästa run.
- AC: Att nå platsen returnerar hela den tappade summan.

**US-2.5 [MVP]** Som spelare vill jag förstå att bara min senaste död räknas, så att reglerna är tydliga.
- AC: Max en aktiv Essens-hög i världen. Dör jag igen ersätts den gamla och den försvinner permanent.
- AC: Varning i UI när jag är på väg att dö med en obärgad hög ute (första gångerna).

**US-2.6 [MVP]** Som spelare vill jag kunna spendera Essens på både permanenta uppgraderingar och tillfälliga boosts för nästa run, så att jag kan välja strategi.
- AC: Två flikar/kategorier vid checkpoint och i hubben: Permanent / Nästa run.
- AC: Minst 5 permanenta och 3 tillfälliga uppgraderingar i MVP.

---

## Epic 3: Strid

**US-3.1 [MVP]** Som spelare vill jag slåss turbaserat med full manuell kontroll, så att strider handlar om beslut, inte reflexer.
- AC: Tydlig turordning synlig i UI.
- AC: Ingen tidspress på spelarens tur.

**US-3.2 [MVP]** Som spelare vill jag ha 2-4 aktiva abilities plus en basattack, så att strider är taktiska men greppbara på en mobilskärm.
- AC: Abilities som stora tryckbara knappar, spelbart med en hand i portrait.
- AC: Cooldowns eller resurskostnad (mana/stamina) per ability.

**US-3.3 [MVP]** Som spelare vill jag möta olika fiendetyper med olika beteenden, så att strider inte känns likadana.
- AC: Minst 5 fiendetyper i MVP med minst 2 distinkta beteenden (t.ex. melee, ranged, healer).

**US-3.4 [V2]** Som spelare vill jag kunna se fiendens intention (vad den gör nästa tur), så att jag kan spela runt den.
- AC: Ikon ovanför fienden visar nästa handling.

---

## Epic 4: Karaktär och klassning genom val

**US-4.1 [MVP]** Som spelare vill jag börja som en svag, oklassad karaktär, så att min resa mot styrka känns förtjänad.
- AC: Startkaraktären har bara basattack och 1 enkel ability.

**US-4.2 [MVP]** Som spelare vill jag forma min klass genom val under spelets gång (level ups, altare, drops), så att min gubbe blir min egen.
- AC: Vid level up presenteras 2-3 val som drar mot fighter, mage eller rogue.
- AC: Efter 3-4 val i samma riktning låses en klassidentitet upp med en signatur-ability.
- AC: Tre riktningar i MVP: fighter, mage, rogue.

**US-4.3 [V2]** Som spelare vill jag kunna gå djupare i min klass (subklasser/specialiseringar), så att det finns långsiktig build-variation.
- AC: Minst 2 specialiseringar per grundriktning.

**US-4.4 [MVP]** Som spelare vill jag kunna skapa nya karaktärer och börja från noll, så att jag kan testa andra builds.
- AC: Minst 3 karaktärsslots.
- AC: Varje karaktär har egen progression, Essens och Essens-hög.

**US-4.5 [MVP]** Som spelare vill jag att mina permanenta uppgraderingar består mellan runs på samma karaktär, så att jag blir starkare över tid.
- AC: Perma-uppgraderingar överlever döden och nollställs aldrig.

---

## Epic 5: Loot

**US-5.1 [MVP]** Som spelare vill jag hitta loot (vapen, rustning, föremål) under runs, så att varje run kan förändra min build.
- AC: Loot droppar från minibossar, bossar och kistor.
- AC: Minst 3 rariteter i MVP.

**US-5.2 [MVP]** Som spelare vill jag att loot följer samma risk-regler som Essens, så att systemet är konsekvent.
- AC: Osäkrad loot tappas vid död och ligger i samma hög som Essensen.
- AC: Loot säkras när jag avslutar en run vid checkpoint.

**US-5.3 [V2]** Som spelare vill jag ha ett förråd i hubben, så att jag kan spara utrustning mellan karaktärer eller builds.

---

## Epic 6: Bossar och minibossar

**US-6.1 [MVP]** Som spelare vill jag möta en boss i slutet av varje run, så att runs har en klimax.
- AC: 1 boss i MVP med minst 2 faser eller mekaniker.
- AC: Bossen droppar garanterad loot och stor Essens-mängd.

**US-6.2 [MVP]** Som spelare vill jag möta en miniboss mitt i runnen, så att svårigheten trappas upp.
- AC: 1 miniboss-typ i MVP, placerad runt rum 3-4.

**US-6.3 [V2]** Som spelare vill jag att nya bossar dyker upp i nya områden, så att varje upplåst plats känns unik.

---

## Epic 7: Procedurgenerering

**US-7.1 [MVP]** Som spelare vill jag att varje run genereras slumpmässigt, så att inga två runs är likadana.
- AC: Rumslayout, fiendekomposition och lootplacering slumpas från pooler.
- AC: Checkpoints och boss-rum placeras enligt fasta regler (t.ex. checkpoint efter rum 3 och 6).

**US-7.2 [MVP]** Som spelare vill jag att min dödsplats går att nå igen trots ny generering, så att corpse-run-mekaniken fungerar.
- AC: Dödsplatsen definieras av djup, inte exakt rum. Högen placeras på motsvarande djup i nästa run.

---

## Epic 8: Hubb och meta

**US-8.1 [MVP]** Som spelare vill jag ha en hubb mellan runs där jag ser min karaktär, spenderar Essens och startar nästa run.
- AC: Hubben innehåller: uppgraderingsträd, karaktärsvy, run-start.

**US-8.2 [V2]** Som spelare vill jag att hubben växer och förändras när jag gör progress, så att jag ser min resa.

---

## Epic 9: Onboarding

**US-9.1 [MVP]** Som ny spelare vill jag lära mig spelet genom min första run, inte genom textväggar, så att jag kommer igång direkt.
- AC: Första runnen är delvis scriptad: lär ut strid, Essens, checkpoint-valet och (gärna via en billig död) tappa/hämta-mekaniken.
- AC: Max 3 popup-rutor totalt.

---

## Epic 10: Monetisering

**US-10.1 [MVP]** Som spelare vill jag kunna spela hela spelet gratis med ads, så att tröskeln är noll.
- AC: Interstitial ads endast mellan runs, aldrig mitt i en run.

**US-10.2 [MVP]** Som spelare vill jag kunna köpa bort alla ads med ett engångsköp, så att jag slipper störningar.
- AC: Ett IAP, tydligt pris, syns i hubben.

**US-10.3 [V2, valfritt]** Som spelare vill jag kunna titta på en frivillig ad för en fördel (t.ex. behålla halva Essensen vid död eller en extra chans att nå min hög), så att ads känns som ett val.
- AC: Alltid frivilligt, aldrig krav för progression.
- OBS: Designbeslut krävs. Detta kan urholka kärnspänningen i Essens-systemet om det blir för generöst.

---

## Epic 11: Teknik och plattform

**US-11.1 [MVP]** Som spelare vill jag kunna spela helt offline, så att spelet funkar överallt.
- AC: All logik och save lokalt på enheten. Ads kräver uppkoppling men blockerar aldrig spel.

**US-11.2 [MVP]** Som spelare vill jag att mitt spel autosparas, så att jag aldrig tappar progress.
- AC: Save efter varje rum, checkpoint och köp.
- AC: Att stänga appen mitt i en run återupptar exakt där jag var (annars blir "stäng appen" ett sätt att fuska sig undan döden).

**US-11.3 [V2]** Som spelare vill jag kunna flytta min save mellan enheter (cloud save), så att jag inte är låst till en telefon.

---

## Öppna designfrågor

1. Ska tillfälliga boosts köpta vid checkpoint gälla resten av nuvarande run, eller nästa run? (Föreslår: resten av nuvarande run om man fortsätter, annars nästa.)
2. Ska checkpoints hela spelaren? (Souls gör det men respawnar fiender. Förslag: heal ja, respawn nej i MVP.)
3. Hur hårt ska tappad loot slå? Att tappa Essens svider, att tappa ett episkt vapen kan kännas orättvist. Överväg att loot av högsta rariteten alltid säkras direkt.
4. Namn på spelet och tema för biom 1.
