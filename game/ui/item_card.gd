class_name ItemCard
extends RefCounted
## **What a thing is, at the hands** (ADR-342, ADR-363): the card the bag draws
## beside the cursor, and the words her pile page names a gift with. Its own
## class so the two screens that judge an item share one answer to *what is
## this worth to her, and what is it for* — it lived inside `BagScreen`, and her
## page reached into the bag for it.
##
## Drawn onto whatever `Control` asks, from that control's theme and palette,
## so a palette swap reaches it exactly as it reaches the screen it is on.

## ## The card (ADR-342)
##
## What the thing under your hands is, in a card beside them rather than a band
## at the foot of the panel — Diablo's tooltip, which every successor kept
## because the eye is already at the cursor. The band it replaces held a name
## and two wrapped lines; the card has room to say what the thing **is to you**:
## where it is worn, what it weighs, how far it is heard, and what she would
## give for it.
const WIDTH: float = 272.0
const PAD: float = 14.0
const NAME_TEXT: int = 17
const TEXT: int = 13
const LEAD: float = 18.0
## How many wrapped lines of description a card will draw. Every authored
## description fits in four at this width; `overflowing()` checks that.
const LINES: int = 5
## How far from the hands the card sits.
const OFFSET: Vector2 = Vector2(22.0, 10.0)

## The key column of a card's numbers.
const KEY: float = 62.0


## **What a thing is worth to her**, as a word and a colour — the only ladder an
## item in this game is on (ADR-342). `DES-008` refuses a rarity ladder: gear is
## sidegrades, and a blue axe that is better than a white one is the treadmill
## `DES-022` exists to prevent. But every item *does* stand somewhere on one
## scale, the one the whole loop turns on — what she would give for it — and
## Diablo's coloured name is the fastest read in the genre. So the name is
## coloured by **tribute**, and the band is written under it as well, because
## `DES-018` will not let a colour carry anything alone.
const WORTH_BANDS: Array[int] = [1, 20, 60, 150]
const WORTH_KEYS: Array[String] = ["worth.none", "worth.trifle",
	"worth.fair", "worth.rich", "worth.kingly"]
const WORTH_TONES: Array[StringName] = [&"worth_none", &"worth_trifle",
	&"worth_fair", &"worth_rich", &"worth_kingly"]


## The band in words. Static, so through `TranslationServer` — `tr()` is a
## node's, and this is asked by her page as well as by the bag.
static func worth_word(band: int) -> String:
	return TranslationServer.translate(WORTH_KEYS[clampi(band, 0, WORTH_KEYS.size() - 1)])


static func worth_band(tribute: int) -> int:
	var band: int = 0
	for floor_of: int in WORTH_BANDS:
		if tribute >= floor_of:
			band += 1
	return band


## The line under the name: where it goes or what it is for.
static func kind_of(definition: ItemResource) -> String:
	if definition.slot != Enums.Slot.NONE:
		return TranslationServer.translate("kind.worn") % [BagScreen.SLOT_LABEL.get(definition.slot, ""),
			TranslationServer.translate("kind.both_hands") if definition.two_handed else ""]
	if definition.tags.has(&"ember"):
		return TranslationServer.translate("kind.ember")
	if definition.tags.has(&"consumable"):
		return TranslationServer.translate("kind.consumable")
	if definition.tags.has(&"glitter"):
		return TranslationServer.translate("kind.glitter")
	if definition.tags.has(&"relic"):
		return TranslationServer.translate("kind.relic")
	if definition.tags.has(&"material"):
		return TranslationServer.translate("kind.material")
	return TranslationServer.translate("kind.carried")


## How many lines `text` wraps to at the card's width.
static func wrapped_lines(text: String, font: Font) -> int:
	var width: float = WIDTH - PAD * 2.0
	var tall: float = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT,
		width, TEXT).y
	return int(ceilf(tall / maxf(font.get_height(TEXT), 1.0) - 0.01))


## The rows of numbers a card ends with.
static func rows(item: ItemInstance) -> Array[PackedStringArray]:
	var said := func(key: String) -> String: return TranslationServer.translate(key)
	var out: Array[PackedStringArray] = []
	out.append(PackedStringArray([said.call("card.weight"), BagScreen.weight_text(item.weight())]))
	if item.clamor() > 0.0:
		out.append(PackedStringArray([said.call("card.heard"), said.call("card.heard_value") % (
			item.clamor() * Config.tuning.clamor_metres_per_unit)]))
	var size: Vector2i = item.definition.grid_size
	out.append(PackedStringArray([said.call("card.takes"),
		said.call("card.takes_value") % [size.x, size.y]]))
	if item.tribute_worth() > 0:
		out.append(PackedStringArray([said.call("card.tribute"), str(item.tribute_worth())]))
	return out


## How tall `item`'s card is, in `font`.
static func height(item: ItemInstance, font: Font) -> float:
	var lines: int = mini(wrapped_lines(item.definition.describe(), font), LINES)
	return (PAD * 2.0 + 24.0 + LEAD + 10.0
		+ lines * font.get_height(TEXT) + 10.0
		+ rows(item).size() * LEAD)


## **The card**, beside the hands and kept on the screen: to the right of the
## cursor, or to the left where the right would run off it. Drawn onto `on`,
## in its theme, in the colours `palette` names.
static func draw(on: Control, item: ItemInstance, at: Vector2, palette: Dictionary) -> void:
	var font: Font = on.get_theme_default_font()
	var screen: Vector2 = on.get_viewport_rect().size
	var size := Vector2(WIDTH, height(item, font))
	var origin: Vector2 = at + OFFSET
	if origin.x + size.x > screen.x - 8.0:
		origin.x = at.x - OFFSET.x - size.x
	origin.y = clampf(origin.y, 8.0, maxf(8.0, screen.y - size.y - 8.0))
	var card := Rect2(origin.round(), size)
	on.get_theme_stylebox(&"panel", MenuStyle.FRAME).draw(on.get_canvas_item(), card)
	var left: float = card.position.x + PAD
	var width: float = card.size.x - PAD * 2.0
	var y: float = card.position.y + PAD + 16.0
	var band: int = worth_band(item.tribute_worth())
	on.draw_string(on.get_theme_font(&"font", MenuStyle.DISPLAY_WARM), Vector2(left, y),
		item.definition.display(), HORIZONTAL_ALIGNMENT_LEFT, width, NAME_TEXT,
		palette[WORTH_TONES[band]] as Color)
	y += LEAD
	on.draw_string(font, Vector2(left, y), "%s · %s" % [worth_word(band),
		kind_of(item.definition)], HORIZONTAL_ALIGNMENT_LEFT, width, TEXT,
		palette[&"dim"] as Color)
	y += 10.0
	on.draw_rect(Rect2(left, y - 4.0, width, 1.0), Color(palette[&"line"] as Color, 0.8))
	y += font.get_ascent(TEXT)
	on.draw_multiline_string(font, Vector2(left, y), item.definition.describe(),
		HORIZONTAL_ALIGNMENT_LEFT, width, TEXT, LINES, palette[&"text"] as Color)
	y += mini(wrapped_lines(item.definition.describe(), font), LINES) \
		* font.get_height(TEXT) - font.get_ascent(TEXT) + 10.0
	on.draw_rect(Rect2(left, y - 4.0, width, 1.0), Color(palette[&"line"] as Color, 0.8))
	y += 12.0
	for row: PackedStringArray in rows(item):
		on.draw_string(font, Vector2(left, y), row[0], HORIZONTAL_ALIGNMENT_LEFT,
			KEY, TEXT, palette[&"dim"] as Color)
		on.draw_string(font, Vector2(left + KEY, y), row[1], HORIZONTAL_ALIGNMENT_LEFT,
			width - KEY, TEXT, palette[&"text"] as Color)
		y += LEAD
