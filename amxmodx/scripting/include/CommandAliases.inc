#if defined _command_aliases_included
	#endinput
#endif
#define _command_aliases_included

/**
 * Максимальная длина строки алиаса
 */
#define COMMAND_ALIASES_ALIAS_MAX_LEN 64

/**
 * Максимальная длина строки команды
 */
#define COMMAND_ALIASES_COMMAND_MAX_LEN 64


/**
 * Принудительная инициализация плагина.
 * 
 * @note Рекомендуется вызывать перед первым вызовом `CommandAliases_Add`.
 * @note Если плагин уже был инициализирован, то ничего не произойдёт.
 * 
 * @noreturn
 */
native CommandAliases_Init();

/**
 * Добавление алиаса.
 * 
 * @note Перед первым вызовом этого натива рекомендуется вызывать `CommandAliases_Init`.
 * 
 * @param alias     Алиас.
 * @param command   Команда.
 * 
 * @noreturn
 */
native CommandAliases_Add(const alias[], const command[]);
