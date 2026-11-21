class_name UIPalette extends RefCounted
## The UI colours in one place. Desaturated and pastel, to match the world: warm paper
## panels, dark brown-red text, no pure white or black. Scenes and theme files carry
## copies of these numbers (they can't read constants); scripts should use this.

## Panel background: an off-white yellow-brown.
const PAPER := Color(0.929, 0.878, 0.761)
## Hovered or selected panel: a little darker.
const PAPER_DARK := Color(0.859, 0.792, 0.647)
## Normal text: a dark warm brown-red.
const TEXT := Color(0.42, 0.176, 0.149)
## Hover, focus and highlighted text: a lighter rust.
const ACCENT := Color(0.66, 0.28, 0.18)
## Inactive or disabled text.
const MUTED := Color(0.62, 0.45, 0.38)
