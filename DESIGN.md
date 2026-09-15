# ClipNest design

A quiet native macOS utility. The owner's fixed, centered selection panel and simple
icon define the direction; system interaction conventions take priority over decoration.

- System light/dark appearance, SF system typography, a restrained teal accent.
- 560 × 520 point panel, centered on the display containing the pointer, no dragging.
- Search above a compact chronological list. Selected row is tinted and outlined.
- One click or Return copies; arrows navigate; Escape dismisses; original app regains focus.
- Native controls, visible keyboard focus, VoiceOver labels, no custom motion or dependency.
- Empty, paused, permission-denied, storage-error, and no-results states explain the next action.

The app icon is a teal tile with two ivory sheets. The generated source and prompt live
in `Artwork/`; the asset catalog contains the complete macOS icon size set.
