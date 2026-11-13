class_name MoonmartShopProgression
extends RefCounted

## Optional commercial and comfort progression. Nothing in this manager is
## required to unlock essential narrative content.
signal progression_changed
signal cleanliness_changed(value: float)
signal milestone_awarded(milestone_id: String)

var reputation := 0
var harmony := 0
var cleanliness := 82.0
var proficiency_points: Dictionary = {}
var awarded_milestones: Dictionary = {}
var owned_upgrades: Dictionary = {}
var reputation_tiers: Array[Dictionary] = []
var proficiency_definitions: Dictionary = {}
var upgrade_definitions: Dictionary = {}
var milestone_definitions: Dictionary = {}
var cleanliness_config: Dictionary = {}
var harmony_config: Dictionary = {}

func setup(config: Dictionary) -> void:
	reputation_tiers.clear()
	for tier in config.get("reputation_tiers", []):
		if tier is Dictionary and not String(tier.get("id", "")).is_empty():
			reputation_tiers.append(tier.duplicate(true))
	reputation_tiers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("threshold", 0)) < int(b.get("threshold", 0)))
	proficiency_definitions.clear()
	for row in config.get("proficiencies", []):
		if row is Dictionary and not String(row.get("id", "")).is_empty():
			proficiency_definitions[String(row.id)] = row.duplicate(true)
			proficiency_points[String(row.id)] = maxi(0, int(proficiency_points.get(String(row.id), 0)))
	upgrade_definitions.clear()
	for row in config.get("upgrades", []):
		if row is Dictionary and not String(row.get("id", "")).is_empty():
			upgrade_definitions[String(row.id)] = row.duplicate(true)
	milestone_definitions.clear()
	for row in config.get("milestones", []):
		if row is Dictionary and not String(row.get("id", "")).is_empty():
			milestone_definitions[String(row.id)] = row.duplicate(true)
	cleanliness_config = config.get("cleanliness", {}).duplicate(true)
	harmony_config = config.get("harmony", {}).duplicate(true)
	cleanliness = clampf(float(cleanliness_config.get("initial", cleanliness)), 0.0, 100.0)
	harmony = clampi(harmony, int(harmony_config.get("minimum", 0)), int(harmony_config.get("maximum", 100)))
	progression_changed.emit()

func award_reputation(amount: int) -> int:
	if amount <= 0:
		return reputation
	reputation += amount
	progression_changed.emit()
	return reputation

func award_harmony(amount: int) -> int:
	if amount <= 0:
		return harmony
	harmony = clampi(harmony + amount, int(harmony_config.get("minimum", 0)), int(harmony_config.get("maximum", 100)))
	progression_changed.emit()
	return harmony

func award_proficiency(proficiency_id: String, points: int = 1) -> int:
	if points <= 0 or not proficiency_definitions.has(proficiency_id):
		return proficiency_rank(proficiency_id)
	var row: Dictionary = proficiency_definitions[proficiency_id]
	var thresholds: Array = row.get("rank_thresholds", [0, 10, 25, 45, 70])
	var cap := int(thresholds.back()) if not thresholds.is_empty() else 0
	proficiency_points[proficiency_id] = mini(cap, int(proficiency_points.get(proficiency_id, 0)) + points)
	progression_changed.emit()
	return proficiency_rank(proficiency_id)

## Awards a configured content milestone at most once per save. Milestones are
## explicit IDs so callers can safely report the same event repeatedly.
func award_milestone(milestone_id: String) -> Dictionary:
	if awarded_milestones.has(milestone_id):
		return {"ok": false, "already_awarded": true, "milestone_id": milestone_id}
	if not milestone_definitions.has(milestone_id):
		return {"ok": false, "reason": "unknown_milestone", "milestone_id": milestone_id}
	var reward: Dictionary = milestone_definitions[milestone_id]
	var rep_before := reputation
	var harmony_before := harmony
	var rank_before := proficiency_rank(String(reward.get("proficiency", "")))
	award_reputation(int(reward.get("reputation", 0)))
	award_harmony(int(reward.get("harmony", 0)))
	var proficiency_id := String(reward.get("proficiency", ""))
	if not proficiency_id.is_empty():
		award_proficiency(proficiency_id, int(reward.get("proficiency_points", 0)))
	awarded_milestones[milestone_id] = true
	milestone_awarded.emit(milestone_id)
	return {
		"ok": true,
		"milestone_id": milestone_id,
		"reputation_gained": reputation - rep_before,
		"harmony_gained": harmony - harmony_before,
		"proficiency": proficiency_id,
		"rank_before": rank_before,
		"rank_after": proficiency_rank(proficiency_id)
	}

func improve_cleanliness(amount: float) -> float:
	if amount <= 0.0:
		return cleanliness
	cleanliness = clampf(cleanliness + amount, 0.0, 100.0)
	cleanliness_changed.emit(cleanliness)
	progression_changed.emit()
	return cleanliness

func perform_cleaning_action(action_id: String) -> float:
	var actions: Dictionary = cleanliness_config.get("actions", {})
	return improve_cleanliness(float(actions.get(action_id, 0.0)))

func complete_shift() -> float:
	var loss := maxf(0.0, float(cleanliness_config.get("loss_per_completed_shift", 1.0)))
	cleanliness = clampf(cleanliness - loss, 0.0, 100.0)
	cleanliness_changed.emit(cleanliness)
	progression_changed.emit()
	return cleanliness

func current_reputation_tier() -> Dictionary:
	var selected: Dictionary = reputation_tiers[0] if not reputation_tiers.is_empty() else {"id": "little_corner_shop", "name": "Little Corner Shop", "threshold": 0}
	for tier in reputation_tiers:
		if reputation >= int(tier.get("threshold", 0)):
			selected = tier
	return selected.duplicate(true)

func reputation_tier_index() -> int:
	var selected_index := 0
	for index in range(reputation_tiers.size()):
		if reputation >= int(reputation_tiers[index].get("threshold", 0)):
			selected_index = index
	return selected_index

func proficiency_rank(proficiency_id: String) -> int:
	if not proficiency_definitions.has(proficiency_id):
		return 0
	var thresholds: Array = proficiency_definitions[proficiency_id].get("rank_thresholds", [0, 10, 25, 45, 70])
	var points := int(proficiency_points.get(proficiency_id, 0))
	var rank := 0
	for index in range(thresholds.size()):
		if points >= int(thresholds[index]):
			rank = index
	return rank

func proficiency_rank_name(proficiency_id: String) -> String:
	if not proficiency_definitions.has(proficiency_id):
		return "Unknown"
	var row: Dictionary = proficiency_definitions[proficiency_id]
	var names: Array = row.get("rank_names", [])
	var index := clampi(proficiency_rank(proficiency_id), 0, maxi(0, names.size() - 1))
	return String(names[index]) if not names.is_empty() else "Rank %d" % (index + 1)

func optional_harmony_tier() -> int:
	var tier := 0
	for threshold in harmony_config.get("optional_thresholds", [25, 50, 75, 100]):
		if harmony >= int(threshold):
			tier += 1
	return tier

## Returns a quote only. The caller must validate and atomically remove the
## listed currency through the inventory/economy facade, then call commit_upgrade.
func purchase_upgrade(upgrade_id: String) -> Dictionary:
	if owned_upgrades.has(upgrade_id):
		return {"ok": false, "reason": "already_owned", "upgrade_id": upgrade_id}
	var available := _available_upgrade(upgrade_id)
	if available.is_empty():
		return {"ok": false, "reason": "locked_or_unknown", "upgrade_id": upgrade_id}
	return {
		"ok": true,
		"upgrade_id": upgrade_id,
		"currency": String(available.get("currency", "coins")),
		"cost": maxi(0, int(available.get("cost", 0))),
		"upgrade": available,
		"commit_required": true
	}

func available_upgrades() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for upgrade_id in upgrade_definitions:
		var row := _available_upgrade(String(upgrade_id))
		if not row.is_empty():
			result.append(row)
	return result

## Call only after the facade has successfully validated and spent the quoted cost.
func commit_upgrade(upgrade_id: String) -> bool:
	if owned_upgrades.has(upgrade_id) or _available_upgrade(upgrade_id).is_empty():
		return false
	owned_upgrades[upgrade_id] = true
	progression_changed.emit()
	return true

func has_upgrade(upgrade_id: String) -> bool:
	return bool(owned_upgrades.get(upgrade_id, false))

func _available_upgrade(upgrade_id: String) -> Dictionary:
	if not upgrade_definitions.has(upgrade_id) or owned_upgrades.has(upgrade_id):
		return {}
	var row: Dictionary = upgrade_definitions[upgrade_id]
	var required_tier := String(row.get("minimum_reputation_tier", ""))
	if not required_tier.is_empty() and reputation_tier_index() < _tier_index(required_tier):
		return {}
	if harmony < int(row.get("minimum_harmony", 0)):
		return {}
	for required_upgrade in row.get("requires_upgrades", []):
		if not has_upgrade(String(required_upgrade)):
			return {}
	return row.duplicate(true)

func _tier_index(tier_id: String) -> int:
	for index in range(reputation_tiers.size()):
		if String(reputation_tiers[index].get("id", "")) == tier_id:
			return index
	return 2147483647

func export_state() -> Dictionary:
	return {
		"reputation": reputation,
		"harmony": harmony,
		"cleanliness": cleanliness,
		"proficiency_points": proficiency_points.duplicate(true),
		"awarded_milestones": awarded_milestones.duplicate(true),
		"owned_upgrades": owned_upgrades.duplicate(true)
	}

func import_state(data: Dictionary) -> void:
	reputation = maxi(0, int(data.get("reputation", 0)))
	harmony = clampi(int(data.get("harmony", 0)), int(harmony_config.get("minimum", 0)), int(harmony_config.get("maximum", 100)))
	cleanliness = clampf(float(data.get("cleanliness", cleanliness_config.get("initial", 82.0))), 0.0, 100.0)
	var saved_points: Dictionary = data.get("proficiency_points", {})
	for proficiency_id in proficiency_definitions:
		var row: Dictionary = proficiency_definitions[proficiency_id]
		var thresholds: Array = row.get("rank_thresholds", [])
		var maximum := int(thresholds.back()) if not thresholds.is_empty() else 0
		proficiency_points[proficiency_id] = clampi(int(saved_points.get(proficiency_id, 0)), 0, maximum)
	awarded_milestones = data.get("awarded_milestones", {}).duplicate(true)
	owned_upgrades = data.get("owned_upgrades", {}).duplicate(true)
	cleanliness_changed.emit(cleanliness)
	progression_changed.emit()
