/obj/machinery/clonepod/fullupgrade/Initialize()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/machine/clonepod(null)
	component_parts += new /obj/item/stock_parts/manipulator/femto(null)
	component_parts += new /obj/item/stock_parts/manipulator/femto(null)
	component_parts += new /obj/item/stock_parts/scanning_module/triphasic(null)
	component_parts += new /obj/item/stock_parts/scanning_module/triphasic(null)
	component_parts += new /obj/item/stack/cable_coil/cut(null)
	component_parts += new /obj/item/stack/cable_coil/cut(null)
	component_parts += new /obj/item/stack/sheet/glass(null)
	
	RefreshParts()