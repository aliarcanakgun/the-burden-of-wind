extends Node

func _ready() -> void:
	%intro_cam.make_current()
	
	$intro_anim.play("fade")
	await $intro_anim.animation_finished
	
	$intro_anim.play("intro")
	await $intro_anim.animation_finished
	$intro_anim.play_backwards("intro")
	await $intro_anim.animation_finished
	
	$intro_anim.play("intro2")
	await $intro_anim.animation_finished
	$intro_anim.play_backwards("intro2")
	await $intro_anim.animation_finished
	
	$intro_anim.play("intro3")
	await $intro_anim.animation_finished
	$intro_anim.play_backwards("intro3")
	await $intro_anim.animation_finished
	
	$intro_anim.play_backwards("fade")
	await $intro_anim.animation_finished
	
	$"../shed/Wooden_Table/cage".hide()
	
	%player.visible = true
	%player.activate_camera()
	%player.movement_disabled = false
	%player.hud_visible = true
	%player.fire_damage_rate = 8.0
	
	$intro_anim.play("fade")
