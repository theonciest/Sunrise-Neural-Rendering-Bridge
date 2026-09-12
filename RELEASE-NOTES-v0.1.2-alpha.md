# STAR 💫 LIFTER v0.1.2-alpha

Comparison + ReShade interaction polish release.

## New

- Bundles `KageBlink - SideBySide.fx`.
- Bundles `KageBlink - HDR LOG Sliders.fx`.
- **F7** toggles the Star Lifter side-by-side comparison view.
- **F5** saves a matched ReShade **Before + After** screenshot pair.
- **F6** toggles the complete ReShade effect chain.
- `CONFIGURE-STAR-LIFTER.bat` applies the recommended ReShade input/hotkey settings without replacing the user's existing preset.

## ReShade interaction fix

Star Lifter now configures ReShade with `InputProcessing=2`, so Destiny does not continue receiving mouse/keyboard input while the ReShade overlay is open. This prevents camera movement in the background while adjusting sliders or making visual comparisons.

## Side-by-side ordering

For correct comparison behavior:

```text
DLSSCompare_Capture   <- FIRST / TOP
...everything else...
DLSSCompare_Output    <- LAST / BOTTOM
```

The configurator attempts to enforce this ordering automatically in the active preset and backs that preset up first.

## Screenshot behavior

`F5` uses ReShade's native `SaveBeforeShot=1` behavior, so a single keypress creates both the pre-effect and post-effect images from the same screenshot request.

## Existing coexistence fix retained

The validated V7 Project Sunrise + patched ReShade coexistence architecture is unchanged from v0.1.1-alpha. Project Sunrise's protected `steam_api64.dll` remains untouched.
