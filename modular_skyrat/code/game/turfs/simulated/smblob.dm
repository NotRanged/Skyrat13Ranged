// QUALITY COPYPASTA
/turf/closed/wall/supermatter
	name = "Supermatter Sea"
	desc = "THE END IS right now actually."
	icon='modular_skyrat/icons/turf/space.dmi'
	icon_state = "bluespacecrystal1"

	light_range = 10
	light_power = 5
	light_color="#0066FF"
	explosion_block = INFINITY

	var/next_check=0
	var/list/avail_dirs = list(NORTH,SOUTH,EAST,WEST)

	dynamic_lighting = 0

/turf/closed/wall/supermatter/Initialize()
	START_PROCESSING(SSobj,src)

/turf/closed/wall/supermatter/New()
	return ..()

/turf/closed/wall/supermatter/Destroy()
	STOP_PROCESSING(SSobj,src)
	return ..()

/turf/closed/wall/supermatter/process()

	// Only check infrequently.
	if(next_check>world.time)
		return

	// No more available directions? Shut down process().
	if(avail_dirs.len==0)
		STOP_PROCESSING(SSobj,src)
		return 1

	// We're checking, reset the timer.
	next_check = world.time+5 SECONDS

	// Choose a direction.
	var/pdir = pick(avail_dirs)
	avail_dirs -= pdir
	var/turf/T=get_step(src,pdir)
	if(istype(T, /turf/closed/wall/supermatter/))
		avail_dirs -= pdir
		return

	// EXPAND DONG
	if(isturf(T))
		// This is normally where a growth animation would occur
		spawn(10)
			// Nom.
			for(var/atom/movable/A in T)
				if(A)
					if(istype(A,/mob/living))
						qdel(A)
						A = null
					else if(istype(A,/mob)) // Observers, AI cameras.
						continue
					qdel(A)
					qdel(A)
					A = null
				CHECK_TICK
			T.ChangeTurf(type)
			var/turf/closed/wall/supermatter/SM = T
			if(SM.avail_dirs)
				SM.avail_dirs -= get_dir(T, src)

/turf/closed/wall/supermatter/attack_paw(mob/user as mob)
	return attack_hand(user)

/turf/closed/wall/supermatter/attack_robot(mob/user as mob)
	if(Adjacent(user))
		return attack_hand(user)
	else
		to_chat(user, "<span class = \"warning\">What the fuck are you doing?</span>")
	return

// /vg/: Don't let ghosts fuck with this.

/turf/closed/wall/supermatter/attack_ai(mob/user as mob)
	return

/turf/closed/wall/supermatter/attack_hand(mob/user as mob)
	user.visible_message("<span class=\"warning\">\The [user] reaches out and touches \the [src]... And then blinks out of existance.</span>",\
		"<span class=\"danger\">You reach out and touch \the [src]. Everything immediately goes quiet. Your last thought is \"That was not a wise decision.\"</span>",\
		"<span class=\"warning\">You hear an unearthly noise.</span>")

	playsound(src, 'sound/effects/supermatter.ogg', 50, 1)

	Consume(user)

/turf/closed/wall/supermatter/attackby(obj/item/weapon/W as obj, mob/living/user as mob)
	user.visible_message("<span class=\"warning\">\The [user] touches \a [W] to \the [src] as a silence fills the room...</span>",\
		"<span class=\"danger\">You touch \the [W] to \the [src] when everything suddenly goes silent.\"</span>\n<span class=\"notice\">\The [W] flashes into dust as you flinch away from \the [src].</span>",\
		"<span class=\"warning\">Everything suddenly goes silent.</span>")

	playsound(src, 'sound/effects/supermatter.ogg', 50, 1)

	Consume(W)


/turf/closed/wall/supermatter/Bumped(atom/AM)
	if(istype(AM, /mob/living))
		AM.visible_message("<span class=\"warning\">\The [AM] slams into \the [src] inducing a resonance... \his body starts to glow and catch flame before flashing into ash.</span>",\
		"<span class=\"danger\">You slam into \the [src] as your ears are filled with unearthly ringing. Your last thought is \"Oh, fuck.\"</span>",\
		"<span class=\"warning\">You hear an unearthly noise as a wave of heat washes over you.</span>")
	else
		AM.visible_message("<span class=\"warning\">\The [AM] smacks into \the [src] and rapidly flashes to ash.</span>",\
		"<span class=\"warning\">You hear a loud crack as you are washed with a wave of heat.</span>")

	playsound(src, 'sound/effects/supermatter.ogg', 50, 1)

	Consume(AM)


/turf/closed/wall/supermatter/proc/Consume(atom/AM)
	if(isliving(AM))
		var/mob/living/user = AM
		if(user.status_flags & GODMODE)
			return
		message_admins("[src] has consumed [key_name_admin(user)] [ADMIN_JMP(src)].")
		investigate_log("has consumed [key_name(user)].", INVESTIGATE_SUPERMATTER)
		user.dust(force = TRUE)
	else if(istype(AM, /obj/singularity))
		return
	else if(isobj(AM))
		if(!iseffect(AM))
			var/suspicion = ""
			if(AM.fingerprintslast)
				suspicion = "last touched by [AM.fingerprintslast]"
				message_admins("[src] has consumed [AM], [suspicion] [ADMIN_JMP(src)].")
			investigate_log("has consumed [AM] - [suspicion].", INVESTIGATE_SUPERMATTER)
		qdel(AM)

	//Some poor sod got eaten, go ahead and irradiate people nearby.
	radiation_pulse(src, 3000, 2, TRUE)
	for(var/mob/living/L in range(10))
		investigate_log("has irradiated [key_name(L)] after consuming [AM].", INVESTIGATE_SUPERMATTER)
		if(L in view())
			L.show_message("<span class='danger'>As \the [src] slowly stops resonating, you find your skin covered in new radiation burns.</span>", MSG_VISUAL,\
				"<span class='danger'>The unearthly ringing subsides and you notice you have new radiation burns.</span>", MSG_AUDIBLE)
		else
			L.show_message("<span class='italics'>You hear an unearthly ringing and notice your skin is covered in fresh radiation burns.</span>", MSG_AUDIBLE)


/turf/closed/wall/supermatter/singularity_act()
	return

/turf/closed/wall/supermatter/no_spread
	avail_dirs = list()