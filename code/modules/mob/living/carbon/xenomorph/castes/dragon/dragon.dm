/mob/living/carbon/xenomorph/dragon
	caste_base_type = /mob/living/carbon/xenomorph/dragon
	name = "Dragon"
	icon = 'icons/Xeno/2x2_Xenos.dmi'
	icon_state = "Dragon Walking"
	// desc = "todo"
	health = 450
	maxHealth = 450
	plasma_stored = 300
	pixel_x = -16
	old_x = -16
	tier = XENO_TIER_FOUR
	upgrade = XENO_UPGRADE_ZERO
	mob_size = MOB_SIZE_BIG
	var/obj/effect/dragon_wings/wing_effect

/mob/living/carbon/xenomorph/dragon/update_icons(state_change = TRUE)
	. = ..()
	if(wing_effect && state_change)
		UnregisterSignal(src, COMSIG_XENOMORPH_PLASMA_CHANGE)
		vis_contents.Remove(wing_effect)
		QDEL_NULL(wing_effect)

	if(!resting && xeno_caste && !wing_effect)
		wing_effect = new()
		update_wing_alpha()
		vis_contents += wing_effect
		RegisterSignal(src, COMSIG_XENOMORPH_PLASMA_CHANGE, .proc/update_wing_alpha)
		overlays += emissive_appearance(wing_effect.icon, wing_effect.icon_state)

/mob/living/carbon/xenomorph/dragon/Destroy()
	. = ..()
	if(wing_effect)
		QDEL_NULL(wing_effect)

/mob/living/carbon/xenomorph/dragon/proc/update_wing_alpha()
	SIGNAL_HANDLER
	var/alpha_result = (plasma_stored / xeno_caste.plasma_max) * 255
	wing_effect.alpha = clamp(round(alpha_result), 0, 255)
