# Regenerate with `make demo`. Needs vhs, nvim >= 0.10 and a logged-in claude CLI.
# The recording makes one real claude request.

Output assets/demo.gif
Output assets/demo.mp4

Require nvim
Require claude

Set Shell "bash"
Set FontSize 20
Set Width 1200
Set Height 640
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 60ms

Hide
Type "nvim -i NONE -u assets/demo/init.lua assets/demo/example.go" Enter
Sleep 1s
Show

Sleep 1s
# Select the function body (lines 10-16).
Type "10G"
Sleep 300ms
Type "V6j"
Sleep 800ms
Type " hv"
Sleep 800ms
Type "make this idiomatic Go"
Sleep 500ms
Escape
Sleep 300ms
Type "w"

# Wait for claude to reply and herald to replace the lines.
Wait+Screen@60s /range users/
Sleep 3s

# Undo, then redo.
Type "u"
Sleep 2s
Ctrl+R
Sleep 3s
