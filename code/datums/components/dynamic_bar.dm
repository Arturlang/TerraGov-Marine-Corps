/**
 * A component to manage a dynamic bar using a single bar icon, using alpha masks to cut out,
 * unwanted parts of the bar
 */
/datum/component/dynamic_bar

/datum/component/dynamic_bar/Initialize(
	icon/bar_icon = icon('icons/mob/hud/xeno_health.dmi', 'health100'),
	bar_name = "health"
)
	. = ..()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE


