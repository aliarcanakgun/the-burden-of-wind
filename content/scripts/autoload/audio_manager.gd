extends Node

var master_volume := 1.0
var sfx_volume := 1.0
var ui_volume := 1.0
var bgm_volume := 1.0

func _process(_delta: float) -> void:
	AudioServer.set_bus_volume_db(0, master_volume)
	AudioServer.set_bus_volume_db(1, sfx_volume)
	AudioServer.set_bus_volume_db(2, ui_volume)
	AudioServer.set_bus_volume_db(3, bgm_volume)

func play_sfx(stream: AudioStream, pitch_variance: float = 0.0, volume_linear := 1.0, custom_bus := "") -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	player.stream = stream
	player.bus = "sfx" if custom_bus.is_empty() else custom_bus
	player.volume_linear = volume_linear
	player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	
	player.play()
	
	player.finished.connect(player.queue_free)
