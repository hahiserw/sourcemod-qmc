#include <sourcemod>


// should be more than enough
#define INPUT_LENGTH_MAX 20

// stop searching after that many matches
#define MATCHED_INDEXES_MAX 10

// to not write it twice
#define INFO_NAME        "Quick map changer"
#define INFO_DESCRIPTION \
	"Type a few letters of a map's name to quickly change the map"


new Handle:g_MapList = INVALID_HANDLE;
new g_mapFileSerial  = -1;

new g_mapListMatchedIndexes[MATCHED_INDEXES_MAX];


public Plugin:myinfo =
{
	name        = INFO_NAME,
	author      = "hahiserw",
	description = INFO_DESCRIPTION,
	version     = "1.2",
	url         = "https://github.com/hahiserw/sourcemod-qmc"
};


public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("qmc.phrases");

	RegAdminCmd("qmc", Command_Qmc, ADMFLAG_CHANGEMAP, INFO_DESCRIPTION);

	g_MapList = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
}


// just as in mapchooser.sp
public OnConfigsExecuted()
{
	if (ReadMapList(g_MapList,
					g_mapFileSerial,
					"qmc",
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		!= INVALID_HANDLE)
	{
		if (g_mapFileSerial == -1)
		{
			LogError("Unable to create a valid map list.");
		}
	}
}


public Action:Command_Qmc(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: qmc <few_letters_of_mapname> [mode]");

		return Plugin_Handled;
	}

	new String:input[INPUT_LENGTH_MAX];
	new String:mode[INPUT_LENGTH_MAX];
	GetCmdArg(1, input, sizeof(input));
	GetCmdArg(2, mode, sizeof(mode));

	new matches = FindMatchingMaps(input);

	switch (matches)
	{
	case -1:
		{
			ReplyToCommand(client, "There is some error in getting map list");

			return Plugin_Stop;
		}

	case 0:
		{
			ReplyToCommand(client, "%t", "No mathing maps found for", input);
		}

	case 1:
		{
			ChangeToFirstMatchingMap(client, mode);
		}

	default:
		{
			if (matches < MATCHED_INDEXES_MAX)
			{
				decl String:map[PLATFORM_MAX_PATH];
				decl String:map_first[PLATFORM_MAX_PATH];

				new bool:first_map_substring = true;
				new map_first_size = sizeof(map_first);

				new index = g_mapListMatchedIndexes[0];
				GetArrayString(g_MapList, index, map_first, map_first_size);

				// see if first map's name is substring of another ones
				// if it is, user probably wanted to change to it
				// eg. `qmc bhz` could match dm_biohazard and dm_biohazard_cal,
				// but if user wanted the former they would type `qmc bhzc`
				for (new i = 1; i < matches; i++)
				{
					index = g_mapListMatchedIndexes[i];
					GetArrayString(g_MapList, index, map, sizeof(map));

					if (strncmp(map_first, map[i], map_first_size) == 0)
					{
						first_map_substring = false;
						break;
					}
				}

				if (first_map_substring)
				{
					ChangeToFirstMatchingMap(client, mode);

					return Plugin_Handled;
				}

				ReplyToCommand(client, "%t", "Found x matching maps:",
							   matches);

				for (new i = 0; i < matches; i++)
				{
					index = g_mapListMatchedIndexes[i];
					GetArrayString(g_MapList, index, map, sizeof(map));

					ReplyToCommand(client, map);
				}
			}
			else
			{
				ReplyToCommand(client, "%t",
							   "Too many matching maps found for", input);
			}
		}
	}

	return Plugin_Handled;
}


public ChangeToFirstMatchingMap(client, const String:mode[])
{
	decl String:map[PLATFORM_MAX_PATH];

	new index = g_mapListMatchedIndexes[0];
	GetArrayString(g_MapList, index, map, sizeof(map));

	if (!strlen(mode)) {
		ShowActivity(client, "%t", "Changing map", map);
		LogAction(client, -1, "\"%L\" changed map to \"%s\"", client, map);

		new Handle:dp;
		CreateDataTimer(3.0, Timer_ChangeMap, dp);
		WritePackString(dp, map);
		return;
	}

	// dry run
	if (strcmp(mode, "?", false) == 0)
	{
		ReplyToCommand(client, map);
		return;
	}

	new command_length = INPUT_LENGTH_MAX + 3;
	decl String:command[command_length];

	// read aliases from a configuration file?
	if (strcmp(mode, "vm", false) == 0)
	{
		strcopy(command, command_length, "sm_votemap");
	}
	else if (strcmp(mode, "nm", false) == 0)
	{
		strcopy(command, command_length, "sm_nextmap");
	}


	// first check if mode is a cvar since every cvar is also a command?

	// cvar
	strcopy(command, command_length, mode);

	new Handle:mode_convar = FindConVar(command);

	if (!mode_convar)
	{
		strcopy(command, command_length, "sm_");
		StrCat(command, command_length, mode);

		mode_convar = FindConVar(command);
	}

	if (mode_convar)
	{
		LogAction(client, -1, "\"%L\" set console variable \"%s\" to \" %s\"", client, mode, map);
		SetConVarString(mode_convar, map);
		return;
	}


	// command
	strcopy(command, command_length, mode);

	bool run_command = false;

	if (CommandExists(command))
	{
		run_command = true;
	}
	else
	{
		strcopy(command, command_length, "sm_");
		StrCat(command, command_length, mode);

		if (CommandExists(command))
		{
			run_command = true;
		}
	}

	if (run_command)
	{
		LogAction(client, -1, "\"%L\" called \"%s %s\"", client, command, map);
		ServerCommand("%s %s", command, map);
		return;
	}


	ReplyToCommand(client, "%t", "No such cvar nor command:", command);
}


public FindMatchingMaps(const String:input[])
{
	new map_count = GetArraySize(g_MapList);

	if (!map_count)
	{
		return -1;
	}

	new matches = 0;
	decl String:map[PLATFORM_MAX_PATH];

	for (new i = 0; i < map_count; i++)
	{
		GetArrayString(g_MapList, i, map, sizeof(map));

		if (FuzzyCompare(input, map))
		{
			g_mapListMatchedIndexes[matches] = i;
			matches++;

			if (matches >= MATCHED_INDEXES_MAX)
			{
				break;
			}
		}
	}

	return matches;
}


// just as in basecommands/map.sp
public Action:Timer_ChangeMap(Handle:hTimer, Handle:dp)
{
	decl String:map[PLATFORM_MAX_PATH];

	ResetPack(dp);
	ReadPackString(dp, map, sizeof(map));

	ForceChangeLevel(map, INFO_NAME);

	return Plugin_Stop;
}


// shamelessly ripped off of https://github.com/bevacqua/fuzzysearch
public FuzzyCompare(const String:needle[], const String:haystack[])
{
	new hlen = strlen(haystack);
	new nlen = strlen(needle);

	if (nlen > hlen)
	{
		return false;
	}

	if (nlen == hlen)
	{
		return strcmp(needle, haystack) == 0;
	}

	new n = 0;
	new h = 0;
	new p = 0;

	for (; n < nlen; n++)
	{
		new nch = needle[n];

		while (h < hlen)
		{
			if (nch == haystack[h])
			{
				h++;
				p++;
				break;
			}

			h++;
		}
	}

	return p == nlen;
}


// vim: ft=sourcepawn
