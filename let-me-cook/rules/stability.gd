class_name Stability
## Burger stability from locked solid layer positions.
## 1.0 is rock solid; the burger collapses below Balance.stability_threshold.


## `layers` are bottom to top, each {"x": float, "width": float}.
static func compute(layers: Array[Dictionary], balance: Balance) -> float:
	var stability := 1.0
	for i in range(1, layers.size()):
		var below: Dictionary = layers[i - 1]
		var layer: Dictionary = layers[i]
		var dx := absf(layer.x - below.x)
		# Center past the edge of the layer below: nothing is holding it up.
		if dx > below.width * 0.5:
			return -1.0
		stability -= dx / (minf(below.width, layer.width) * 0.5) * balance.offset_penalty
	var extra_layers := layers.size() - balance.height_free_layers
	if extra_layers > 0:
		stability -= extra_layers * balance.height_penalty
	return stability
