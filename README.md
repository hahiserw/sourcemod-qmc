# Quick map changer

Tired of typing full map name to change it (`!map map_name`)? Don't like
setting up aliases for maps (`!cm map_shortcut`)?

I've got you covered! Quick map changer is what you're looking for.


## Usage

1. Just type in chat: `!qmc lkn`
2. ???
3. Profit, you are now playing on dm_lockdown and you've saved 8 keystrokes!

Note: You might have to type more letters if you have a lot of maps with similar names.

...So you've noticed you'd save 9 keystrokes with `!cm ld`? Yep, that's true,
but if you have some (exotic?) map you don't have shortcut for in pms.cfg you'd
have to type the whole map name (or just set up a shortcut). If that suits you,
then just use `!cm`. (`!cm` is a command from Public Match Server Pack from
<http://hl2dm.net>)

There's also a mode parameter you can use to see what map matches, to set cvars
or call commands.

Usage: `qmc <few_letters_of_mapname> [mode]`<br>
Usage: `qmca <few_letters_of_mapname> [mode]`<br>
where qmc is for maps from mapcycyle file and qmca is for all the maps from
maps folder, and mode might be:
* `?` - don't change current map, just return the matching name
* `vm`, `votemap` or `sm_votemap` - call `sm_votemap` with the matching map as
  a first argument
* `nm`, `nextmap` or `sm_nextmap` - set `sm_nextmap` cvar to the matching map
* other cvars or commands

There are abbreviations for `votemap` and `nextmap`, since they might be used
a lot, `vm` and `nm` respectively. If you want to use sourcemod cvar or command
you don't have to type the `sm_` - it will be prepended to test if there's such
cvar or command.

There's another thing. If you changed mapcycle file and you want to get new
maps in qmc matches (without changing the current map) just type `!qmc !`, and
the maplist will get refreshed.

## More info

* No configuration needed
* It's case sensitive
* Of course you need sourcemod installed on your server to use this plugin
* You can send PR with your translations
* I used this algorithm: <https://github.com/bevacqua/fuzzysearch>


## Installation

* Put scripting/qmc.sp into addons/sourcemod/scripting
* Put plugins/qmc.smx into addons/sourcemod/plugins (or compile it yourself :^)
* Put translations/qmc.phrases.txt into addons/sourcemods/translations
* Also put other qmc.phrases.txt files into their respective folders


## License

MIT
