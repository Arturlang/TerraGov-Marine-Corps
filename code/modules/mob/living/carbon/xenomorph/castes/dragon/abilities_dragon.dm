
/datum/action/ability/activable/xeno/tail_stab
	name = "Tail Stab"
	action_icon_state = "tail_stab"
	desc = "Stab a human with your tail, immobilizing it, and setting it on fire after a moment. Also works while hovering or flying"
	use_state_flags = ABILITY_USE_STAGGERED|ABILITY_IGNORE_HAND_BLOCKED
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_TAIL_STAB
	)
	ability_cost = 100
	cooldown_duration = 7 SECONDS
	var/tail_stab_range = 2
	var/tail_stab_delay = 1.5 SECONDS

/datum/action/ability/activable/xeno/tail_stab/can_use_ability(atom/target, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/target_living = target
	if(!isliving(target) || target_living.stat == DEAD)
		if(!silent)
			owner.balloon_alert(owner, "We can't tail stab that!")
		return FALSE
	// TODO, replace this with something that deals with densities, not sight
	if(!line_of_sight(owner, target, tail_stab_delay))
		if(!silent)
			owner.balloon_alert(owner, "You can't reach the target from here!")
		return FALSE
	return TRUE

// TODO, make it only lock the target on hover or on the ground, and make flying stab not target based
/datum/action/ability/activable/xeno/tail_stab/use_ability(mob/living/carbon/human/target)
	var/mob/living/carbon/xenomorph/owner_xeno = owner
	initial_attack(target, owner_xeno)
	var/tail_stab_start_time = world.time
	if(!do_after(owner_xeno, tail_stab_delay))
		owner_xeno.balloon_alert(owner_xeno, "You give up on lighting [target] on fire!")
		// Remove the remaining stun that's left
		target.AdjustImmobilized(world.time - tail_stab_start_time)
		add_cooldown(cooldown_timer * 0.5)
		return succeed_activate()

	delayed_effect(target, owner_xeno)
	return succeed_activate()

/datum/action/ability/activable/xeno/tail_stab/proc/initial_attack(mob/living/carbon/human/target, mob/living/carbon/xenomorph/owner_xeno)
	var/datum/action/ability/xeno/flight/flight_action = owner_xeno.actions_by_path[/datum/action/ability/xeno/flight]
	var/flight_landing_delay = flight_action.flight.landing_delay
	if(flight_action.flight)
		owner_xeno.remove_status_effect(flight_action.flight)
		addtimer(CALLBACK(src, .proc/landing_effects, target, owner_xeno), flight_landing_delay)
		target.Immobilize(flight_landing_delay)
	else
		tail_stab(target, owner_xeno)
		target.Immobilize(tail_stab_delay)
		owner_xeno.balloon_alert_to_viewers("has tail-stabbed [target]")

/datum/action/ability/activable/xeno/tail_stab/proc/tail_stab(mob/living/carbon/human/target, mob/living/carbon/xenomorph/owner_xeno, damage_modifier = 1)
	target.apply_damage((owner_xeno.xeno_caste.melee_damage * owner_xeno.xeno_melee_damage_modifier) * damage_modifier, BRUTE, "chest")
	playsound(owner_xeno, 'sound/weapons/alien_tail_attack.ogg', 50, TRUE)
	log_combat(owner_xeno, target, "fire tail-stabbed")
	owner_xeno.balloon_alert_to_viewers("has tail-stabbed [target]")
	owner_xeno.face_atom(target)
	target.apply_status_effect(STATUS_EFFECT_DRAGONFIRE, 10)
	owner_xeno.do_attack_animation(target, ATTACK_EFFECT_GRAB)

/datum/action/ability/activable/xeno/tail_stab/proc/landing_effects(mob/living/carbon/human/target, mob/living/carbon/xenomorph/owner_xeno)
	owner_xeno.balloon_alert_to_viewers("[owner_xeno] swoops down and impales [target] with it's tail!")
	tail_stab(target, owner_xeno, 2)
	playsound(get_turf(owner_xeno), 'sound/effects/droppod_impact.ogg', 100)
	for(var/turf/affected_tiles AS in RANGE_TURFS(2, owner_xeno.loc))
		affected_tiles.Shake(4, 4, 1 SECONDS)

/datum/action/ability/activable/xeno/tail_stab/proc/delayed_effect(mob/living/carbon/human/target, mob/living/carbon/xenomorph/owner_xeno)
	owner_xeno.do_attack_animation(target, ATTACK_EFFECT_REDSTAB)
	owner_xeno.balloon_alert_to_viewers("has set [target] on fire with their tail!")
	target.apply_status_effect(STATUS_EFFECT_DRAGONFIRE, 40)
	add_cooldown()


/datum/action/ability/activable/xeno/xeno_spit/fireball
	name = "Spit a fireball"
	action_icon_state = "dragon_fireball"
	desc = "Belch a fiery fireball at your foes."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_FIREBALL
	)
	use_state_flags = ABILITY_IGNORE_HAND_BLOCKED
	// icon_from_ammo = FALSE
	var/flying_spit_delay = 1.5 SECONDS
	var/flying_spit_type = /datum/ammo/flamethrower/dragon_fire/flying
	var/obj/effect/firey_cloud_animation/flying_spit_target_effect

/datum/action/ability/activable/xeno/xeno_spit/fireball/update_button_icon()
	return

/datum/action/ability/activable/xeno/xeno_spit/fireball/alternate_fire_at(obj/projectile/newspit, datum/ammo/spit_ammo, mob/living/carbon/xenomorph/spitter_xeno)
	var/datum/ammo/flamethrower/dragon_fire/dragon_spit = newspit
	if(istype(dragon_spit))
		dragon_spit.hivenumber = spitter_xeno.hivenumber

	if(spitter_xeno.has_status_effect(STATUS_EFFECT_FLIGHT))
		return flight_spit(newspit, spit_ammo, owner)
	// Hover spit uses normal spit, but with a different animation
	if(spitter_xeno.has_status_effect(STATUS_EFFECT_HOVER))
		return hover_spit(newspit, spit_ammo, owner)
	else
		// returning false will make it spit normally
		return FALSE

// The flight spit drops down from above, as the dragon is invisible while flying
/datum/action/ability/activable/xeno/xeno_spit/fireball/proc/flight_spit(obj/projectile/newspit, datum/ammo/spit_ammo, mob/living/carbon/xenomorph/spitter_xeno)
	var/turf/target_turf = get_turf(target)
	flying_spit_target_effect = new(target_turf)

	// First, make it invisible and move it into place
	newspit.y_offset = 255
	newspit.alpha = 0
	newspit.forceMove(target_turf)
	newspit.dir = SOUTH
	
	RegisterSignal(newspit, COMSIG_PROJ_HIT, .proc/delete_effect)
	animate(newspit, alpha = 255, time = 0.5 SECONDS)
	animate(newspit, pixel_y = 0, time = flying_spit_delay, easing = CIRCULAR_EASING)
	addtimer(CALLBACK(src, .proc/flight_spit_drop, newspit, target, target_turf), flying_spit_delay)
	return continue_autospit()

/datum/action/ability/activable/xeno/xeno_spit/fireball/proc/delete_effect()
	QDEL_NULL(flying_spit_target_effect)

/datum/action/ability/activable/xeno/xeno_spit/fireball/proc/flight_spit_drop(obj/projectile/newspit, turf/target_turf)
	// Make a list of all the mobs in the turf
	var/list/mobs_in_turf = list()
	if(!current_target || !isliving(current_target))
		for(var/mob/living/mob_in_turf in target_turf)
			mobs_in_turf += mob_in_turf
	else
		mobs_in_turf += current_target
	// We don't want to run this multiple times, because this causes fire to be spawned, and that causes damage
	var/mob/living/mob_to_hurt = pick(mobs_in_turf) 
	mob_to_hurt.do_projectile_hit(newspit)
	qdel(newspit)

// The hover spit should account for the dragon's offset
/datum/action/ability/activable/xeno/xeno_spit/fireball/proc/hover_spit(obj/projectile/newspit, datum/ammo/spit_ammo, mob/living/carbon/xenomorph/spitter_xeno)
	ENABLE_BITFIELD(newspit.ammo?.flags_ammo_behavior, AMMO_PASS_THROUGH_MOVABLE)
	newspit.pixel_y = spitter_xeno.pixel_y
	animate(newspit, pixel_y = 0, time = flying_spit_delay, easing = LINEAR_EASING)
	newspit.fire_at(target, owner, null, spit_ammo.max_range, spit_ammo.shell_speed)


/datum/action/ability/xeno/flight
	name = "Skycall"
	action_icon_state = "dragon_flight_up"
	desc = "Take flight and rain hell upon your enemies! Right click the action button to descend, and left click to ascend."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_FLIGHT
	)
	cooldown_duration = 2 MINUTES
	use_state_flags = ABILITY_IGNORE_HAND_BLOCKED
	var/list/blacklisted_areas = list(
		/area/shuttle/dropship,
		/area/shuttle
	)
	var/datum/status_effect/xeno/flight/flight

/datum/action/ability/xeno/flight/give_action(mob/living/L)
	. = ..()
	RegisterSignal(L, COMSIG_XENO_FLIGHT_END, .proc/on_flight_end)

/datum/action/ability/xeno/flight/can_use_action(atom/target, silent, override_flags)
	. = ..()
	if(!.)
		return FALSE
	var/invalid_area = FALSE
	var/area/owner_area = get_area(owner)
	// Figure out some bullshit how the dragon can fly on the marine ship, or make it 
	if(owner_area.ceiling >= CEILING_UNDERGROUND)
		if(!silent)
			owner.balloon_alert(owner, "the ceiling here stops you from flying!")
		return FALSE
	for(var/area/area in blacklisted_areas)
		if(istype(owner_area, area))
			invalid_area = TRUE
			break
	if(invalid_area)
		if(!silent)
			owner.balloon_alert(owner, "can't fly in this area!")
		return FALSE
	var/mob/living/carbon/xenomorph/xeno_owner = owner
	if(xeno_owner?.on_fire)
		if(!silent)
			owner.balloon_alert(owner, "you can't fly while on fire!")
		return FALSE
	// Have to have atleast 50% plasma to fly
	var/plasma_required = xeno_owner?.xeno_caste?.plasma_max * 0.5
	if(plasma_required >= xeno_owner?.plasma_stored)
		if(!silent)
			owner.balloon_alert(owner, "you need to have atleast [plasma_required] plasma to fly!")
		return FALSE

/datum/action/ability/xeno/flight/action_activate()
	var/mob/living/carbon/xenomorph/owner_xeno = owner
	if(flight)
		if(flight.transition)
			return fail_activate()
		// If we're already at max height, tell them how to descend
		if(flight.type == STATUS_EFFECT_FLIGHT)
			// Tempting to make this land you immediately,
			//  but having a way to inform the player how to do it themselves is better
			owner_xeno.balloon_alert(owner_xeno, "right click the action button to land!")
			return fail_activate()

	if(!ascend_to_flight_or_hover())
		return

	var/takeoff_time = flight.total_takeoff_time()
	if(!do_after(owner_xeno, takeoff_time))
		add_cooldown(1 MINUTES)
		alternate_action_activate(TRUE)
		return fail_activate()

	update_action_icon()

/datum/action/ability/xeno/flight/alternate_action_activate(silent = FALSE)
	var/mob/living/carbon/xenomorph/owner_xeno = owner
	if(!flight)
		if(!silent)
			owner_xeno.balloon_alert(owner_xeno, "you're not flying!")
		fail_activate()
		return
	switch(flight.type)
		if(STATUS_EFFECT_FLIGHT)
			owner_xeno.apply_status_effect(STATUS_EFFECT_HOVER)
			update_action_icon()
		if(STATUS_EFFECT_HOVER)
			// Full cooldown if we're landed on the ground.
			add_cooldown()
			land()

/datum/action/ability/xeno/flight/proc/ascend_to_flight_or_hover()
	var/mob/living/carbon/xenomorph/owner_xeno = owner
	var/is_hovering = flight?.type == STATUS_EFFECT_HOVER
	var/status_effect_to_add
	if(!flight)
		status_effect_to_add = STATUS_EFFECT_HOVER
		var/area/owner_area = get_area(owner)
		owner_xeno.balloon_alert_to_viewers(owner_area.ceiling ? "burrows through the thin roof!" : "takes flight!")

	else if(is_hovering)
		status_effect_to_add = STATUS_EFFECT_FLIGHT
		var/turf/turf = get_turf(owner)
		turf.balloon_alert_to_viewers("[owner_xeno] begins to ascend to the skies!")

	if(!status_effect_to_add)
		return FALSE

	flight = owner_xeno.apply_status_effect(status_effect_to_add)
	return TRUE

/datum/action/ability/xeno/flight/proc/on_flight_end(mob/source_mob)
	SIGNAL_HANDLER
	action_icon_state = initial(action_icon_state)

/datum/action/ability/xeno/flight/proc/update_action_icon()
	if(!flight)
		action_icon_state = "dragon_flight_up"
	else 
		action_icon_state = flight?.type == STATUS_EFFECT_FLIGHT ? "dragon_flight_crash" : "dragon_flight_hover"

/datum/action/ability/xeno/flight/proc/land()
	if(!flight)
		CRASH("Somehow called land() while not even flying, or the pointer to the flight effect was missing")

	var/mob/living/carbon/xenomorph/owner_xeno = owner
	owner_xeno.remove_status_effect(flight)
	flight = null

/datum/action/ability/xeno/flight/remove_action(mob/living/L)
	. = ..()
	if(flight)
		land()

	UnregisterSignal(L, COMSIG_XENO_FLIGHT_END)


/datum/action/ability/activable/xeno/charge/hell_dash
	name = "Hell Dash"
	desc = "Dash forward at high speeds, burning anything in your path."
	action_icon_state = "hell_drive"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_HELL_DASH
	)
	cooldown_duration = 40 SECONDS
	ability_cost = 200
	charge_distance = DRAGON_CHARGE_RANGE
	charge_speed =  DRAGON_CHARGE_SPEED
	var/fire_radius = 1

/datum/action/ability/activable/xeno/charge/hell_dash/use_ability(atom/A)
	. = ..()
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, .proc/drop_fire)

/datum/action/ability/activable/xeno/charge/hell_dash/charge_complete()
	. = ..()
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)

/datum/action/ability/activable/xeno/charge/hell_dash/proc/drop_fire()
	SIGNAL_HANDLER
	// Drop fire around the owner
	for(var/turf/turf in RANGE_TURFS(fire_radius, owner))
		turf.ignite(20, 20, "purple", 0, 20, BURN_HUMANS, /obj/flamer_fire/autosmoothing/resin)


/datum/action/ability/activable/xeno/incendiary_gas
	name = "Incendiary Gas"
	desc = "Throws a glob that expands into a cloud of incendiary gas that can be ignited with your other abilities"
	action_icon_state = "hell_gas"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_INCENDIARY_GAS
	)
	cooldown_duration = 2 MINUTES
	ability_cost = 500

/datum/action/ability/activable/xeno/incendiary_gas/use_ability(atom/A)
	owner.face_atom(A)
	// todo: figure out a better message
	owner.balloon_alert_to_viewers("[owner] starts to gather flaming resin in it's mouth!")
	if(!do_after(owner, 3 SECONDS, FALSE, null, BUSY_ICON_HOSTILE))
		add_cooldown(cooldown_timer * 0.1)
		return
	var/obj/projectile/P = new /obj/projectile(get_turf(owner))
	var/datum/ammo/xeno/boiler_gas/incendiary/glob = new /datum/ammo/xeno/boiler_gas/incendiary()
	var/mob/living/carbon/xenomorph/owner_xeno = owner
	glob.hive_number = owner_xeno.hivenumber
	P.generate_bullet(glob)
	P.fire_at(A, owner, null, glob.max_range, glob.shell_speed)
	add_cooldown()
