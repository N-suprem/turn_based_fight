extends Node2D

@export var sprite : CompressedTexture2D
@export var description : String
@export var type_1 : String
@export var type_2 : String
@export var max_health : int
var current_health : int
@export var attack : float
@export var defense : float
@export var base_speed : int
var speed : int
@export var attacks : Array

func _ready():
	$Sprite2D.texture = sprite
	speed = base_speed
	current_health = max_health
	$ProgressBar.max_value = max_health
	$ProgressBar.value = current_health

func change_health(change):
	current_health -= change
	if change > 0:
		$AnimationPlayer.play("hurt")
	elif change < 0:
		if current_health > max_health:
			current_health = max_health
		$AnimationPlayer.play("recover")
	var tween = get_tree().create_tween()
	tween.tween_property($ProgressBar, "value", current_health, 0.5)
	await tween.finished
