class_name HidingRules
extends RefCounted
## The one rule of hiding: she is hidden only while crouched AND her crouched
## silhouette is fully inside a piece of cover. Partly covered = visible.


static func is_hidden(is_crouching: bool, body_rect: Rect2, cover_rects: Array[Rect2]) -> bool:
	if not is_crouching:
		return false
	for cover in cover_rects:
		if cover.encloses(body_rect):
			return true
	return false
