/datum/xeno_caste/dragon
	caste_name = "Dragon"
	display_name = "Dragon"
	caste_desc = "A xenomorph with wings and a tail, and a fiery breath."
	caste_type_path = /mob/living/carbon/xenomorph/dragon
	evolve_min_xenos = 14
	tier = XENO_TIER_FOUR
	upgrade = XENO_UPGRADE_BASETYPE
	wound_type = "dragon"

	// *** Melee Attacks *** //
	melee_damage = 27

	// *** Speed *** //
	speed = 0.1

	// *** Plasma *** //
	plasma_max = 1200
	plasma_gain = 70

	// *** Health *** //
	max_health = 700

	deevolves_to = list(/mob/living/carbon/xenomorph/ravager, /mob/living/carbon/xenomorph/shrike, /mob/living/carbon/xenomorph/gorger, /mob/living/carbon/xenomorph/praetorian)

	// *** Flags *** //
	can_flags = CASTE_CAN_BE_QUEEN_HEALED|CASTE_CAN_BE_LEADER|CASTE_CAN_BE_GIVEN_PLASMA

	// *** Defense *** //
	soft_armor = list(MELEE = 0, BULLET = 15, LASER = 15, ENERGY = 15, BOMB = 15, BIO = 60, FIRE = 85, ACID = 60)
	hard_armor = list(MELEE = 0, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 0, BIO = 0, FIRE = 30, ACID = 0)

	// *** Ranged Attack *** //
	spit_delay = 1 SECONDS
	spit_types = list(/datum/ammo/flamethrower/dragon_fire)

	// *** Minimap Icon *** //
	// minimap_icon = "todo"

	// *** Abilities *** //
	actions = list(
		/datum/action/ability/xeno_action/xeno_resting,
		/datum/action/ability/xeno_action/watch_xeno,
		/datum/action/ability/activable/xeno/psydrain,
		/datum/action/ability/activable/xeno/tail_stab,
		/datum/action/ability/xeno/flight,
		/datum/action/ability/activable/xeno/xeno_spit/fireball,
		/datum/action/ability/activable/xeno/charge/hell_dash
	)

/datum/xeno_caste/dragon/normal
	upgrade_name = XENO_UPGRADE_NORMAL

/datum/xeno_caste/dragon/primordial
	upgrade_name = "Primordial"
	caste_desc = "You can feel heat radiating from this xenomorph, best watch the skies, or be lit aflame."
	upgrade = XENO_UPGRADE_PRIMO
	primordial_message = "The skies shall be blotted out by your fiery breath, and the earth shall tremble at your approach. You are the dragon, and you are primordial."

	// *** Abilities *** //
	actions = list(
		/datum/action/ability/xeno_action/xeno_resting,
		/datum/action/ability/xeno_action/watch_xeno,
		/datum/action/ability/activable/xeno/psydrain,
		/datum/action/ability/activable/xeno/tail_stab,
		/datum/action/ability/xeno/flight,
		/datum/action/ability/activable/xeno/xeno_spit/fireball,
		/datum/action/ability/activable/xeno/charge/hell_dash,
		/datum/action/ability/activable/xeno/incendiary_gas
	)
