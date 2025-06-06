/// Shows a header name on top when you investigate an appearance/image
/image/vv_get_header()
	. = list()
	var/icon_name = "<b>[icon || "null"]</b><br/>"
	. += replacetext(icon_name, "icons/obj", "") // shortens the name. We know the path already.
	if(icon)
		. += icon_state ? "\"[icon_state]\"" : "(icon_state = null)"

/// Makes nice short vv names for images
/image/debug_variable_value(name, level, datum/owner, sanitize, display_flags)
	var/display_name = "[type]"
	if("[src]" != "[type]") // If we have a name var, let's use it.
		display_name = "[src] [type]"

	var/display_value
	var/list/icon_file_name = splittext("[icon]", "/")
	if(length(icon_file_name))
		display_value = icon_file_name[length(icon_file_name)]
	else
		display_value = "null"

	if(icon_state)
		display_value = "[display_value]:[icon_state]"

	var/display_ref = get_vv_link_ref()
	return "<a href='byond://?_src_=vars;[HrefToken()];vars=[display_ref]'>[display_name] (<span class='value'>[display_value]</span>) [display_ref]</a>"

/// Returns the ref string to use when displaying this image in the vv menu of something else
/image/proc/get_vv_link_ref()
	return REF(src)

// It is endlessly annoying to display /appearance directly for stupid byond reasons, so we copy everything we care about into a holder datum
// That we can override procs on and store other vars on and such.
/mutable_appearance/appearance_mirror
	// So people can see where it came from
	var/appearance_ref

// arg is actually an appearance, typed as mutable_appearance as closest mirror
/mutable_appearance/appearance_mirror/New(mutable_appearance/appearance_father)
	. = ..() // /mutable_appearance/New() copies over all the appearance vars MAs care about by default
	appearance_ref = REF(appearance_father)

// This means if the appearance loses refs before a click it's gone, but that's consistent to other datums so it's fine
// Need to ref the APPEARANCE because we just free on our own, which sorta fucks this operation up you know?
/mutable_appearance/appearance_mirror/get_vv_link_ref()
	return appearance_ref

/mutable_appearance/appearance_mirror/can_vv_get(var_name)
	var/static/datum/beloved = new()
	if(beloved.vars.Find(var_name)) // If datums have it, get out
		return FALSE
	// If it is one of the two args on /image, yeet (I am sorry)
	if(var_name == NAMEOF(src, realized_overlays))
		return FALSE
	if(var_name == NAMEOF(src, realized_underlays))
		return FALSE

	// Could make an argument for this but I think they will just confuse people, so yeeet
	if(var_name == NAMEOF(src, vis_contents))
		return FALSE
	return ..()

/mutable_appearance/appearance_mirror/vv_get_var(var_name)
	// No editing for you
	var/value = vars[var_name]
	return "<li style='backgroundColor:white'>(READ ONLY) [var_name] = [_debug_variable_value(var_name, value, 0, src, sanitize = TRUE, display_flags = NONE)]</li>"

/mutable_appearance/appearance_mirror/vv_get_dropdown()
	SHOULD_CALL_PARENT(FALSE)

	. = list()
	VV_DROPDOWN_OPTION("", "---")
	VV_DROPDOWN_OPTION(VV_HK_CALLPROC, "Call Proc")
	VV_DROPDOWN_OPTION(VV_HK_MARK, "Mark Object")
	VV_DROPDOWN_OPTION(VV_HK_TAG, "Tag Datum")
	VV_DROPDOWN_OPTION(VV_HK_DELETE, "Delete")
	VV_DROPDOWN_OPTION(VV_HK_EXPOSE, "Show VV To Player")

/proc/get_vv_appearance(mutable_appearance/appearance) // actually appearance yadeeyada
	return new /mutable_appearance/appearance_mirror(appearance)
