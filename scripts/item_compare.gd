class_name ItemCompare
extends RefCounted

const ORDER := ["atk", "def", "hp", "crit", "ls", "spd"]

static func compare(candidate: Dictionary, current: Dictionary) -> Array:
	var rows: Array = []
	for key in ORDER:
		var candidate_value := ItemsData.value(candidate, key)
		var current_value := ItemsData.value(current, key)
		var delta := candidate_value - current_value
		var tone := "neutral"
		if delta > 0.0001:
			tone = "gain"
		elif delta < -0.0001:
			tone = "loss"
		rows.append({
			"key": key,
			"label": ItemsData.STAT_NAME[key],
			"current": current_value,
			"candidate": candidate_value,
			"delta": delta,
			"tone": tone,
		})
	return rows
