extends Node3D

# Keeps the GL thread busy every frame: the box rotates continuously,
# so the render thread is submitting draw calls when the app is
# backgrounded and the engine tears the render thread down. The
# static-label version of this repro did NOT crash — its render
# thread was idle at teardown.

func _process(delta: float) -> void:
	$Box.rotation.y += delta
	$Box.rotation.x += delta * 0.5
