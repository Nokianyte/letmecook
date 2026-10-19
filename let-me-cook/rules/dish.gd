class_name Dish
extends RefCounted
## A finished dish, as served.

var station: Recipe.Station
## Bottom to top for burgers; unordered for smoothies.
var layers: Array[DishLayer] = []
## Set when the dish is served.
var result: ScoreResult = null


func _init(p_station: Recipe.Station) -> void:
	station = p_station


func display_name() -> String:
	return "Burger" if station == Recipe.Station.BURGER else "Smoothie"
