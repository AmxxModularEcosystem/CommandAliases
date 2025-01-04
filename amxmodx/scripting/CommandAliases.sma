#include <amxmodx>
#include <json>
#include <regex>
#include <CommandAliases>

new Trie:aliases = Invalid_Trie;

public plugin_precache() {
    PluginInit();
}

PluginInit() {
    static bool:inited = false;
    if (inited) {
        return;
    }
    inited = true;
    
    register_plugin("Command Aliases", "1.0.1", "ArKaNeMaN");

    aliases = TrieCreate();
    LoadFromFolder(CfgUtils_MakePath("CommandAliases"));
}

// Main

AddAlias(const alias[], const command[]) {
    TrieSetString(aliases, alias, command);
    register_clcmd(alias, "@ClCmd_HandleAlias");
}

@ClCmd_HandleAlias(const playerIndex) {
    new cmd[COMMAND_ALIASES_ALIAS_MAX_LEN];
    ReadArgs(cmd, charsmax(cmd));

    new alias[COMMAND_ALIASES_ALIAS_MAX_LEN];
    new endOfResolvedAlias = ResolveAlias(cmd, alias, charsmax(alias));
    if (endOfResolvedAlias < 1) {
        return PLUGIN_CONTINUE;
    }

    new command[COMMAND_ALIASES_COMMAND_MAX_LEN];
    TrieGetString(aliases, alias, command, charsmax(command));

    client_cmd(playerIndex, "%s %s", command, cmd[endOfResolvedAlias + 1]);
    return PLUGIN_HANDLED;
}

ResolveAlias(const executedCommand[], resolved[], const resolvedLen) {
    copy(resolved, resolvedLen, executedCommand);
    new resolvedCharPointer = strlen(resolved) - 1;

    while (!TrieKeyExists(aliases, resolved)) {
        while (resolvedCharPointer > 0 && resolved[resolvedCharPointer] != ' ') {
            --resolvedCharPointer;
        }

        resolved[resolvedCharPointer] = EOS;

        if (resolvedCharPointer == 0) {
            break;
        }
    }

    return resolvedCharPointer;
}

// Configs

bool:LoadFromFolder(path[]) {
    new file[PLATFORM_MAX_PATH], dirHnd, FileType:fileType;
    dirHnd = open_dir(path, file, charsmax(file), fileType);
    if (!dirHnd) {
        log_amx("[WARNING] Can't open folder '%s'.", path);
        return;
    }

    new Regex:fileNameRegex, ret;
    fileNameRegex = regex_compile("(.+).json$", ret, "", 0, "i");

    do {
        if (
            file[0] == '!'
            || fileType != FileType_File
            || regex_match_c(file, fileNameRegex) <= 0
        ) {
            continue;
        }

        regex_substr(fileNameRegex, 1, file, charsmax(file));
        LoadFromFile(fmt("%s/%s.json", path, file));

    } while (next_file(dirHnd, file, charsmax(file), fileType));

    regex_free(fileNameRegex);
    close_dir(dirHnd);
}

bool:LoadFromFile(const path[]) {
    if (!file_exists(path)) {
        log_amx("[WARNING] File '%s' not found.", path);
        return false;
    }

    new JSON:aliasesJson = json_parse(path, true, true);
    new bool:res = LoadFromJson(aliasesJson);
    if (!res) {
        log_amx("[WARNING] File '%s' loaded with errors.", path);
    }
    json_free(aliasesJson);
    
    return res;
}

bool:LoadFromJson(const JSON:aliasesJson) {
    new bool:res = true;
    if (json_is_array(aliasesJson)) {
        for (new i = 0, ii = json_array_get_count(aliasesJson); i < ii; ++i) {
            new JSON:aliasJson = json_array_get_value(aliasesJson, i);
            if (!json_is_object(aliasJson)) {
                log_amx("[WARNING] Aliases file must contains an array of objects. Item #%d", i);
                res = false;
                json_free(aliasJson);
                continue;
            }

            if (!LoadFromJson(aliasJson)) {
                res = false;
            }

            json_free(aliasJson);
        }
    } else if (json_is_object(aliasesJson)) {
        new alias[COMMAND_ALIASES_ALIAS_MAX_LEN];
        new command[COMMAND_ALIASES_COMMAND_MAX_LEN];

        json_object_get_string(aliasesJson, "Command", command, charsmax(command));

        new JSON:aliasJsonValue = json_object_get_value(aliasesJson, "Alias");
        if (json_is_string(aliasJsonValue)) {
            json_object_get_string(aliasesJson, "Alias", alias, charsmax(alias));
            AddAlias(alias, command);
        } else if (json_is_array(aliasJsonValue)) {
            for (new i = 0, ii = json_array_get_count(aliasJsonValue); i < ii; ++i) {
                json_array_get_string(aliasJsonValue, i, alias, charsmax(alias));
                AddAlias(alias, command);
            }
        }
        json_free(aliasJsonValue);
    } else {
        log_amx("[WARNING] Aliases file must contains an array or an object.");
        res = false;
    }

    return res;
}

// Natives

public plugin_natives() {
    register_native("CommandAliases_Init", "@_Init");
    register_native("CommandAliases_Add", "@_Add");
}

@_Init() {
    PluginInit();
}

@_Add() {
    enum {Arg_Alias = 1, Arg_Command}

    if (aliases == Invalid_Trie) {
        log_error(AMX_ERR_PARAMS, "Attempt interact with command aliases before init them. Call CommandAliases_Init() first.");
        return;
    }

    new alias[COMMAND_ALIASES_ALIAS_MAX_LEN];
    new command[COMMAND_ALIASES_COMMAND_MAX_LEN];

    get_string(Arg_Alias, alias, charsmax(alias));
    get_string(Arg_Command, command, charsmax(command));

    AddAlias(alias, command);
}

// Utils

ReadArgs(out[], const outLen) {
    new writenCells = 0;
    new paramPointer = 0;
    new paramsCount = read_argc();

    while (writenCells < outLen && paramPointer < paramsCount) {
        if (writenCells > 0) {
            out[writenCells++] = ' ';
        }

        writenCells += read_argv(paramPointer, out[writenCells], outLen - writenCells);
        ++paramPointer;
    }

    return writenCells;
}

// Simplificated https://github.com/AmxxModularEcosystem/CustomWeaponsAPI/blob/master/amxmodx/scripting/Cwapi/CfgUtils.inc#L32-L43
CfgUtils_MakePath(const path[]) {
    static __amxx_configsdir[PLATFORM_MAX_PATH];
    if (!__amxx_configsdir[0]) {
        get_localinfo("amxx_configsdir", __amxx_configsdir, charsmax(__amxx_configsdir));
    }

    new out[PLATFORM_MAX_PATH];
    formatex(out, charsmax(out), "%s/plugins/%s", __amxx_configsdir, path);

    return out;
}
