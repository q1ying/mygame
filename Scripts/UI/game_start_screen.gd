extends Control

const lines_list := [
	"Night falls like ink, and the glory of the Moonshade Kingdom has become nothing but a fading memory. Corrupted shadows devour every inch of the land, and upon the altar, even the stars have dimmed.",
	"You—bearing the ancestral sword and a heavy burden—step into this cursed world.",
	"As darkness swirls around you, you sense that ahead lies either the dawn of redemption or the final judgment.",
	"Darkness has fallen, dawn has yet to arrive, and your journey is the kingdom’s last hope."
]

@export var bgm: AudioStream

var current_line := -1
var tween: Tween

@onready var label: Label = $Label

func _ready() -> void:
	show_line(0)
	
	if bgm:
		SoundManager.play_bgm(bgm)

func _input(event: InputEvent) -> void:
	if tween.is_running():
		return
	
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed() and not event.is_echo():
			if current_line + 1< lines_list.size():
				show_line(current_line + 1)
			else:
				Game.change_scene("res://Scenes/level/level1.tscn")
				
				
func show_line(line: int) -> void:
	current_line = line
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	if line > 0:
		tween.tween_property(label, "modulate:a", 0, 1)
	else:
		label.modulate.a = 0
		
	tween.tween_callback(label.set_text.bind(lines_list[line]))
	tween.tween_property(label, "modulate:a", 1, 1)
