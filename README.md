# Minimal reproduction project — Godot issue #124903

Android SIGABRT `FORTIFY: pthread_mutex_lock called on a destroyed mutex`
in the render thread teardown when the app is backgrounded and relaunched.

## Project

Bare Godot 4.6.3 project: one scene (`main.tscn`, a 3D scene with a
continuously rotating box driven by `main.gd`), no plugins, no ads,
`gl_compatibility` renderer. Nothing else.
(`textures/vram_compression/import_etc2_astc=true` is set only because
Godot 4.6.3's Android exporter refuses to validate without it; it is
unrelated to the crash.)

The scene is animated on purpose: the rotating box keeps the GL
thread submitting draw calls every frame, so the render thread is
busy when the app is backgrounded and the engine tears it down.
An earlier version of this project with a static Label scene did
NOT reproduce the SIGABRT — its render thread was idle at teardown,
and the app instead took Godot's force-quit path (SIGKILL, self-
inflicted) on relaunch. The crash is a race inside that teardown,
so the render thread has to be doing work when it starts.

## Steps to reproduce

1. Launch the app on an Android device (reproduced on Pixel 2 Arm
   Virtual API 33 and Pixel 8 Android 16).
2. Wait ~45 seconds on the main screen.
3. Press Home.
4. Relaunch the app from the launcher.

## Observed result

In the full game (eMarriagey, a 3D Godot game) the app crashes
~25 ms after the relaunch starts:

```
FORTIFY: pthread_mutex_lock called on a destroyed mutex
signal 6 (SIGABRT), crashing thread GLThread
top frame: org.godotengine.godot.GodotRenderer.onRenderThreadExiting
```

Process uptime at crash: ~54 s. The same crash reproduces on
Godot 4.7.2 (latest stable at time of writing). Renderer switch
(Vulkan ↔ gl_compatibility) and single-threaded thread model do not
help. See the original report #124903 (closed as "not planned" for
procedural reasons — template/AI-authorship — with no technical
assessment) for the full logcats.

## Test Lab repro

Firebase Test Lab Robo script that reproduces it deterministically:

```json
[{"actions":[{"delayTime":45000,"eventType":"WAIT"},{"eventType":"GO_HOME"}],
  "contextDescriptor":{"condition":"app_under_test_shown"},"id":1000},
 {"actions":[{"delayTime":3000,"eventType":"WAIT"},
  {"command":"monkey -p com.example.godot124903 -c android.intent.category.LAUNCHER 1",
   "eventType":"ADB_SHELL_COMMAND"},
  {"delayTime":10000,"eventType":"WAIT"}],
  "contextDescriptor":{"condition":"default_launcher_shown"},"id":1001}]
```
