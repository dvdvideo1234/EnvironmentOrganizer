**Copyright 2016-08-30 ME !**

**Environment setting organizer for the sandbox game Garry's mod**

This repository contains a tweaker for the in-game environment settings for Garry's mod

The addon simply stores your setting inside some CVARS so you must not run it every time

```
Q: Why did you do this thing and what is its purpose ?
A: Remember the following tweak when building an engine
   "lua_run physenv.SetPerformanceSettings({MaxVelocity = 100000, MaxAngularVelocity = 360000, MaxCollisionsPerObjectPerTimestep = 30, MaxCollisionChecksPerTimestep = 750})"
   This addon is here to meke it run automatically on startup when enabled based on user-defined settings.
   My life was going to be much easier back then when I recorded: https://www.youtube.com/watch?v=herJj_aRJvY

Q: How can I use this thing ?
A: Whenever you change a console variable, a callback for the environment settings adjustment will be triggered,
   which will reload all the settings for the related member into the server "NEW" environment. If you do agree
   with this change you can call a user command to apply it, usually one of the following prefixed "envorganiser_" of course.
     Syntax: "envorganiser_<adjuster-member> <store-container>" ( For example: "envorganiser_setairdensity NEW")
   Value <adjuster-member> must be one of the following:
     setairdensity  --> Applies the air density environment setting
     setgravity     --> Applies the gravity environment setting
     setperformance --> Applies the performance environment settings
   Value <store-container> must be either "NEW" or "OLD".
     When "NEW" is selected, the script adjusts the environment settings directly form the values of the console
       variables dedicated to that member ( For the example above it will load console variable
       "envorganiser_airdensity" into the environment).
     When "OLD" is selected, the script adjusts the environment settings from the stored values
       taken during initialization. This option represents a base/initial/default setting that stores the
       original values, so the user can switch between the server defaults and the personal ones on demand.

Q: So what custom environment variables were included ?
A: Here they are, prefixed with "envorganiser_" of course:
   Member: envSetAirDensity: https://wiki.garrysmod.com/page/Category:number
     airdensity --> The air density of the server
   Member: envSetGravity: https://wiki.garrysmod.com/page/Category:Vector
     gravitydrx --> Component X of the gravity affecting props
     gravitydry --> Component Y of the gravity affecting props
     gravitydrz --> Component Z of the gravity affecting props
   Member: envSetPerformance: https://wiki.garrysmod.com/page/Category:physenv
     perfmaxangvel --> Maximum rotation velocity
     perfmaxlinvel --> Maximum speed of an object
     perfminfrmass --> Minimum mass of an object to be affected by friction
     perfmaxfrmass --> Maximum mass of an object to be affected by friction
     perflooktmovo --> Maximum amount of seconds to precalculate collisions with objects
     perflooktmovw --> Maximum amount of seconds to precalculate collisions with world
     perfmaxcolchk --> Maximum collision checks per tick
     perfmaxcolobj --> Maximum collision per object per tick

Q: Does this organiser has any fail-safe features ?
A: Yes it does.
   A member's value for the environment setting is only set when positive number is given,
     otherwise the "OLD" ( default/fail-safe ) value is loaded.
   The console commands check for a correct storage key and does not apply the settings when the key
     is not either "NEW" or "OLD", defining the storage location the values will be taken from.
     
Q: May I pit this thing to a third-party website ?
A: No ! I will never give you my permission to upload this into third-party websites !
   Instead of doing stupid things, and confuse everbody with your actions, just put a link
   leading to this repository there in a comment. That was not so hard was it !
```
