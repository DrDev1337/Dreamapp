extends Node
## Ads-stub (Epic 10). MVP:t är helt spelbart offline; annonser visas
## bara mellan runs och aldrig mitt i en run (US-10.1). Den här stubben
## byts mot riktig SDK-integration (t.ex. AdMob via godot-admob-plugin)
## utan att anropspunkterna ändras.
##
## US-10.2: ett engångsköp ("Ta bort reklam") sätter Game.ads_removed.
## IAP-flödet är också stubbat – byts mot StoreKit/Play Billing-plugin.

signal interstitial_closed


## Anropas mellan runs (hubb <- death/victory). Aldrig mitt i en run.
func show_interstitial_between_runs() -> void:
	if Game.ads_removed:
		interstitial_closed.emit()
		return
	# TODO: riktig annons här. Stubben "visar" ingenting och går vidare direkt.
	print("[Ads] Interstitial skulle visas här (mellan runs).")
	interstitial_closed.emit()


## IAP-stub (US-10.2). Riktigt köpflöde kopplas in senare.
func purchase_remove_ads() -> void:
	Game.ads_removed = true
	Game.save_game()
	print("[Ads] Reklam borttagen (IAP-stub).")
