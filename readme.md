**Copyright 2016-08-30 ME !**

**Environment setting organizer for the sandbox game Garry's mod**

![EnvironmentOrganizer](https://github.com/dvdvideo1234/EnvironmentOrganizer/blob/master/data/pictures/icon.jpg)

This repository contains a tweaker for the in-game environment settings for Garry's mod

The addon simply stores your setting inside some CVARS so you must not run it every time

```
Q: Why did you do this thing and what is its purpose ?
A: Remember the following tweak when building an engine
   "lua_run physenv.SetPerformanceSettings({MaxVelocity = 100000, MaxAngularVelocity = 360000, MaxCollisionsPerObjectPerTimestep = 30, MaxCollisionChecksPerTimestep = 750})"
   This addon is here to make it run automatically on startup when enabled based on user-defined settings.
   My life was going to be much easier back then when I recorded: https://www.youtube.com/watch?v=herJj_aRJvY

Q: Hey, Did you make the icon of the tool yourself and where is it from ?
A: Yes I did. It's located in Ochindol, Vratsa, Bulgaria and fact is the exact street view I've shot with my phone in march 2016. It was a panorama picture.
   https://www.google.bg/maps/@43.0882408,23.4751913,3a,75y,177.71h,81.92t/data=!3m6!1e1!3m4!1ssN4kRVgtbcKK_SVxgQ_SsQ!2e0!7i13312!8i6656?hl=en
   After that I used a common icon for "settings" using google.

Q: How can I use this script ?
A: Whenever you change a console variable, a callback for the environment settings adjustment will be triggered,
   which will reload all the settings for the related member into the server "user" environment. If you do agree
   with this change you can call a user command to apply it, usually one of the following prefixed "envorg_" of course.
     Syntax: "envorg_<adjuster-member> <store-container>" ( For example: "envorg_setairdensity user")
   Value <adjuster-member> must be one of the following:
     setairdensity  --> Applies the air density environment setting
     setgravity     --> Applies the gravity environment setting
     setperformance --> Applies the performance environment settings
   Value <store-container> must be either "user" or "init".
     When "user" is selected, the script adjusts the environment settings directly form the console
       variables dedicated to the member called ( For the example above it will load console variable
       "envorg_airdensity" into the environment as the new air density value used by the game).
     When "init" is selected, the script adjusts the environment settings from the stored values
       taken during the game initialization. This option represents a base/initial/default/fail-safe setting
       that stores the original values, so the user can switch between the server defaults and the personal
       ones on demand.

Q: So which custom environment variables were included ?
A: Here they are, prefixed with "envorg_" of course:
   Member: envSetAirDensity: https://wiki.garrysmod.com/page/Category:number
   Manage: https://wiki.garrysmod.com/page/physenv/SetAirDensity
     airdensity --> The air density of the server
   Member: envSetGravity: https://wiki.garrysmod.com/page/Category:Vector
   Manage: https://wiki.garrysmod.com/page/physenv/SetGravity
     gravitydrx --> Component X of the gravity affecting props
     gravitydry --> Component Y of the gravity affecting props
     gravitydrz --> Component Z of the gravity affecting props
   Member: envSetPerformance: https://wiki.garrysmod.com/page/Category:physenv
   Manage: https://wiki.garrysmod.com/page/physenv/SetPerformanceSettings
     perfmaxangvel --> Maximum rotation velocity
     perfmaxlinvel --> Maximum speed of an object
     perfminfrmass --> Minimum mass of an object to be affected by friction
     perfmaxfrmass --> Maximum mass of an object to be affected by friction
     perflooktmovo --> Maximum amount of seconds to precalculate collisions with objects
     perflooktmovw --> Maximum amount of seconds to precalculate collisions with world
     perfmaxcolchk --> Maximum collision checks per tick
     perfmaxcolobj --> Maximum collision per object per tick

Q: How can I save my custom settings to a file so everytime when Gmod loads, it reads it?
A: First the envorg_hashvar is set to "user". You have to adjust all the convars in
   "So which custom environment variables were included ?" ( Above ! ) to the desired values for your server,
   then use the <adjuster-member> commands to update the current settings. After you are done, they become
   final as the game is currently using them. You must use "envorg_storevalues <cutom-name>". The
   <cutom-name> parameter can be anything. For example "envorg_storevalues cupcake" will store all
   the current environment settings used in files, located in "envorganizer/" ( grouped by "cupcake" of course )
   If you want to change these, just edit the files related with your <cutom-name> ( cupcake ). Do not worry
   about the cvar spacers. You can use tabs, spaces, or both mixed, so you can align the values one under another
   as you prefer. After you are done with all your changes, you must make the script load your custom settings
   from that file by setting "envorg_hashvar #<cutom-name>" ( For the example above "envorg_hashvar #cupcake"
   And yes I am a brony xD ). The hashtag command can be translated to: "When envorg_hashvar is created assign to
   it <load-file><cutom-name>" where <load-file> is "#" Done. Now the settings will be loaded form the file chosen on startup
   ( Example file: envorganizer/cupcake_<adjuster-member>.txt under "DATA")
N: Here is how the exports should look in case you are wondering.
   https://raw.githubusercontent.com/dvdvideo1234/EnvironmentOrganizer/master/data/envorganizer/maglev_envSetAirDensity.txt
   https://raw.githubusercontent.com/dvdvideo1234/EnvironmentOrganizer/master/data/envorganizer/maglev_envSetGravity.txt
   https://raw.githubusercontent.com/dvdvideo1234/EnvironmentOrganizer/master/data/envorganizer/maglev_envSetPerformance.txt

Q: Does this organizer has any fail-safe features ?
A: Yes it does.
   Envoronmet settings must be managed by a player, who is an admin in single player or on the server directly,
     otherwise the environment will not be modified.
   When loading saving setting to external custom file, <cutom-name> is checked for alphanumeric,
     otherwise nothing will be exported
   A member's value for the environment setting is only set when number in a set of range is given,
     otherwise the "init" ( default/fail-safe ) value is loaded.
   The console commands check for a correct storage key and does not apply the settings when the key
     is not either "user", "init" or "#<cutom-name>", defining the storage location the values will be taken from.

Q: May I pit this thing to a third-party web site ?
A: No ! I will never give you my permission to upload this into third-party websites !
   Instead of doing stupid things, and confuse everybody with your actions, forcing them to use a malicious copy
   of this script, just put a link leading to this repository there in a comment. That was not so hard was it !
```
