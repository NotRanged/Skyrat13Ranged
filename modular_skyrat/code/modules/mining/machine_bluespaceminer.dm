/obj/machinery/mineral/bluespace_miner
	name = "bluespace mining machine"
	desc = "A machine that uses the magic of Bluespace to slowly generate materials and add them to a linked ore silo."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "stacker"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/bluespace_miner
	layer = BELOW_OBJ_LAYER
	var/list/ore_rates = list(/datum/material/iron = 0.3, /datum/material/glass = 0.3, /datum/material/plasma = 0.1,  /datum/material/silver = 0.1, /datum/material/gold = 0.05, /datum/material/titanium = 0.05, /datum/material/uranium = 0.05, /datum/material/diamond = 0.02)
	var/datum/component/remote_materials/materials
	var/obj/item/radio/Radio

	// Parts
	var/manipulator_efficiency = 1	// Increases mining rate, power usage, gas consumption, heat generation
	var/laser_efficiency = 1		// Reduces power consumption, but increases heat generation
	var/bin_efficiency = 1			// Combined with scanner, unlocks better harvest modes, reduces hear generation
	var/scanner_efficiency = 1		// Combined with bins, unlocks better harvest modes
	var/unlocked_modes = 1			// Simple, Intermediate, Advanced, Experimental

	// Operation
	power_channel = EQUIP
	use_power = IDLE_POWER_USE
	var/currently_active = FALSE	// Toggle with empty hand click
	var/selected_mode = 1			// Toggle with alt-click, can only change while offline
	idle_power_usage = 200			// 0.2 kW
	active_power_usage = 200000		// 200 kW. This machine will be /heavy/ on the grid.

	// Percentage efficiencies
	var/harvesting_rate
	var/gas_usage_rate
	var/heat_generation_rate
	var/power_usage_rate

/obj/machinery/mineral/bluespace_miner/Initialize(mapload)
	. = ..()
	materials = AddComponent(/datum/component/remote_materials, "bsm", mapload)
	Radio = new /obj/item/radio(src)
	Radio.listening = 0
	Radio.set_frequency(FREQ_SCIENCE)
	RefreshParts()

/obj/machinery/mineral/bluespace_miner/Destroy()
	materials = null
	QDEL_NULL(Radio)
	return ..()

/obj/machinery/mineral/bluespace_miner/RefreshParts()
	// First see what modes we unlock. Every 2 combined rating unlocks the next, full functionality at 8.
	var/unlock_rating 
	for(var/obj/item/stock_parts/matter_bin/M in component_parts)
		unlock_rating += M.rating
		bin_efficiency = M.rating
	for(var/obj/item/stock_parts/scanning_module/S in component_parts)
		unlock_rating += S.rating
	switch(unlock_rating)
		if(1 to 2)
			unlocked_modes = 1
		if(3 to 4)
			unlocked_modes = 2
		if(5 to 6)
			unlocked_modes = 3
		if(7 to 8)
			unlocked_modes = 4
	
	// Other components relating to efficiency of the machine
	for(var/obj/item/stock_parts/manipulator/MA in component_parts)
		manipulator_efficiency = MA.rating
	for(var/obj/item/stock_parts/micro_laser/ML in component_parts)
		laser_efficiency = ML.rating

	// Percentage efficiencies compared to full T1
	harvesting_rate = 1 + (manipulator_efficiency * 0.25) - 0.25 	// 25% increase per manipulator tier
	gas_usage_rate = 1 + (manipulator_efficiency * 0.1) - 0.1 		// 10% per manipulator tier
	heat_generation_rate = 1 + (manipulator_efficiency * 0.1) + (laser_efficiency * 0.3) - (bin_efficiency * 0.1) - 0.3
	power_usage_rate = 1 + (manipulator_efficiency * 0.2) - (laser_efficiency * 0.25) + 0.05 // Minimum possible is 0.25

/obj/machinery/mineral/bluespace_miner/interact(mob/user) // Open hand click to toggle the miner
	if(anchored)
		if(currently_active)
			deactivate_miner()
			return
		
		// TODO

	else
		to_chat(user, "<span class='warning'>The [src.name] must be anchored first!</span>")

/obj/machinery/mineral/bluespace_miner/AltClick(mob/user) // Toggles harvesting mode
	if(currently_active)
		to_chat(user, "<span class='warning'>The [src.name] must be shut down before you can change its mode.</span>")
		return

	// Prepare for ugly state code
	selected_mode += 1
	if(selected_mode > 4)
		selected_mode = 1
	switch(selected_mode)
		if(1)
			Say("Harvesting mode set to 'Low'.")
		if(2)
			Say("Harvesting mode set to 'Intermediate'.")
		if(3)
			Say("Harvesting mode set to 'Advanced'. Caution is advised.")
		if(4)
			Say("Harvesting mode set to 'Experimental'. Caution is advised.")


/obj/machinery/mineral/bluespace_miner/proc/deactivate_miner()
	if(currently_active)
		currently_active = FALSE
		use_power = IDLE_POWER_USE
		audible_message("The [src] whirrs as it shuts down.")
		return

/obj/machinery/mineral/bluespace_miner/multitool_act(mob/living/user, obj/item/multitool/M)
	if(istype(M))
		if(!M.buffer || !istype(M.buffer, /obj/machinery/ore_silo))
			to_chat(user, "<span class='warning'>You need to multitool the ore silo first.</span>")
			return FALSE

/obj/machinery/mineral/bluespace_miner/examine(mob/user)
	. = ..()
	if(!materials?.silo)
		. += "<span class='notice'>No ore silo connected. Use a multi-tool to link an ore silo to this machine.</span>"
	else if(materials?.on_hold())
		. += "<span class='warning'>Ore silo access is on hold, please contact the quartermaster.</span>"

/obj/machinery/mineral/bluespace_miner/process()
	if(!materials?.silo || materials?.on_hold())
		return
	var/datum/component/material_container/mat_container = materials.mat_container
	if(!mat_container || panel_open || !powered())
		return
	var/datum/material/ore = pick(ore_rates)
	mat_container.bsm_insert((ore_rates[ore] * 1000), ore)

/datum/component/material_container/proc/bsm_insert(amt, var/datum/material/mat)
	if(!istype(mat))
		mat = SSmaterials.GetMaterialRef(mat)
	if(amt > 0 && has_space(amt))
		var/total_amount_saved = total_amount
		if(mat)
			materials[mat] += amt
			total_amount += amt
		else
			for(var/i in materials)
				materials[i] += amt
				total_amount += amt
		return (total_amount - total_amount_saved)
	return FALSE
