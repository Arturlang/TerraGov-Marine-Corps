/**
 * A component to manage a dynamic bar using a single bar icon, using alpha masks to cut out,
 * unwanted parts of the bar, depleted amount is show with a separate icon.
 */
/datum/component/dynamic_bar
	var/list/alpha_mask_args = list(
		"icon" = 'icons/mob/hud/xeno_health.dmi',
		"icon_state" = "health100",
		"filter_name" = "",
		"value" = 0,
		"min" = -32,
		"max" = 0,
		"priority" = 1,
		"time" = 0.4 SECONDS,
		"easing" = SINE_EASING,
		"flags" = ANIMATION_PARALLEL
	)
	var/update_delay = 0.5 SECONDS
	var/obj/effect/overlay/banked_bar_overlay

/datum/component/dynamic_bar/Initialize(list/alpha_mask_args = list())
	if(!isatom(parent) && !isimage(parent))
		return COMPONENT_INCOMPATIBLE
	if(!length(alpha_mask_args) || !alpha_mask_args["filter_name"])
		stack_trace("No bar_name provided for dynamic_bar component on [parent]!")
		return INITIALIZE_HINT_QDEL
	src.alpha_mask_args += alpha_mask_args
	RegisterSignal(parent, COMSIG_DYNAMIC_BAR(alpha_mask_args["filter_name"]), PROC_REF(bank_value_update))
	update_bar(parent, alpha_mask_args["value"], alpha_mask_args)
	create_damage_bar()

/datum/component/dynamic_bar/Destroy()
	. = ..()
	UnregisterSignal(parent, COMSIG_DYNAMIC_BAR(alpha_mask_args["filter_name"]))
	if(banked_bar_overlay)
		var/image/source = parent
		source.vis_contents -= banked_bar_overlay
		QDEL_NULL(banked_bar_overlay)

/datum/component/dynamic_bar/proc/bank_value_update(atom/holder, new_value, list/new_args = list())
	SIGNAL_HANDLER
	update_bar(holder, new_value, new_args)
	addtimer(CALLBACK(src, PROC_REF(update_bar), banked_bar_overlay, new_value, new_args), update_delay, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)

/// Reflects how much of the HP bar you've taken as a separate bar
/datum/component/dynamic_bar/proc/create_damage_bar()
	banked_bar_overlay = new()
	banked_bar_overlay.icon = alpha_mask_args["icon"]
	banked_bar_overlay.icon_state = "damage_bar"
	banked_bar_overlay.vis_flags = VIS_UNDERLAY|VIS_INHERIT_LAYER|VIS_INHERIT_PLANE
	// banked_bar_overlay.vis_flags = VIS_UNDERLAY
	var/image/source = parent
	source.vis_contents += banked_bar_overlay

/datum/component/dynamic_bar/proc/update_bar(atom/holder, new_value, list/new_args = list())
	var/list/mask_args = alpha_mask_args.Copy()
	mask_args += new_args
	mask_args["value"] = new_value

	holder.alpha_mask_hide_transition(arglist(mask_args))

