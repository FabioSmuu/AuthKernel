class_name AuthSchema
extends RefCounted

enum Type { STRING, INT, FLOAT, BOOL, ARRAY, DICTIONARY }

var _rules: Dictionary = {}

# só quem ler o codigo vai saber que da pra usar add_ nas schemas sem sintax sugar.

## Adiciona uma regra de String
func add_string(key: String, options: Variant = null, max_len: int = -1) -> AuthSchema:
	var rule = {"type": Type.STRING, "max_len": max_len, "options": []}
	if options is Array:
		rule["options"] = options
	_rules[key] = rule
	return self

## Adiciona uma regra de Inteiro
func add_int(key: String, min_val: Variant = null, max_val: Variant = null) -> AuthSchema:
	var rule = {"type": Type.INT, "min": -INF, "max": INF}
	if min_val != null: rule["min"] = min_val
	if max_val != null: rule["max"] = max_val
	_rules[key] = rule
	return self

## Adiciona uma regra de Float
func add_float(key: String, min_val: Variant = null, max_val: Variant = null) -> AuthSchema:
	var rule = {"type": Type.FLOAT, "min": -INF, "max": INF}
	if min_val != null: rule["min"] = min_val
	if max_val != null: rule["max"] = max_val
	_rules[key] = rule
	return self

## Adiciona uma regra de Booleano
func add_bool(key: String) -> AuthSchema:
	_rules[key] = {"type": Type.BOOL}
	return self

## Adiciona uma regra de Array
func add_array(key: String) -> AuthSchema:
	_rules[key] = {"type": Type.ARRAY}
	return self

## Adiciona uma regra de Dicionário
func add_dictionary(key: String) -> AuthSchema:
	_rules[key] = {"type": Type.DICTIONARY}
	return self

## Adiciona uma regra de Regex (String)
func add_regex(key: String, pattern: String) -> AuthSchema:
	_rules[key] = {"type": Type.STRING, "regex": pattern, "max_len": -1, "options": []}
	return self

## Adiciona uma regra de String
func string(key: String, options: Variant = null, max_len: int = -1) -> AuthSchema:
	var rule = {"type": Type.STRING, "max_len": max_len, "options": []}
	if options is Array:
		rule["options"] = options
	_rules[key] = rule
	return self

## Adiciona uma regra de Inteiro
func int(key: String, min_val: Variant = null, max_val: Variant = null) -> AuthSchema:
	var rule = {"type": Type.INT, "min": -INF, "max": INF}
	if min_val != null: rule["min"] = min_val
	if max_val != null: rule["max"] = max_val
	_rules[key] = rule
	return self

## Adiciona uma regra de Float
func float(key: String, min_val: Variant = null, max_val: Variant = null) -> AuthSchema:
	var rule = {"type": Type.FLOAT, "min": -INF, "max": INF}
	if min_val != null: rule["min"] = min_val
	if max_val != null: rule["max"] = max_val
	_rules[key] = rule
	return self

## Adiciona uma regra de Booleano
func bool(key: String) -> AuthSchema:
	_rules[key] = {"type": Type.BOOL}
	return self

## Adiciona uma regra de Array
func array(key: String) -> AuthSchema:
	_rules[key] = {"type": Type.ARRAY}
	return self

## Adiciona uma regra de Dicionário
func dictionary(key: String) -> AuthSchema:
	_rules[key] = {"type": Type.DICTIONARY}
	return self

## Adiciona uma regra de Regex (String)
func regex(key: String, pattern: String) -> AuthSchema:
	_rules[key] = {"type": Type.STRING, "regex": pattern, "max_len": -1, "options": []}
	return self

## Cria o schema a partir de um dicionário de definição
func from_dict(definition: Dictionary) -> AuthSchema:
	for key in definition:
		var rule_def = definition[key]
		if typeof(rule_def) == TYPE_STRING:
			_parse_string_rule(key, rule_def)
		elif typeof(rule_def) == TYPE_DICTIONARY:
			_parse_dict_rule(key, rule_def)
	return self

func _parse_string_rule(key: String, type_str: String):
	match type_str.to_lower():
		"string": add_string(key)
		"int", "integer": add_int(key)
		"float", "number": add_float(key)
		"bool", "boolean": add_bool(key)
		"array": add_array(key)
		"dict", "dictionary": add_dictionary(key)

func _parse_dict_rule(key: String, rule_dict: Dictionary):
	# A tentativa de tratamento de 'type' é gritante kk, mas ajuda na inferencia.
	if not rule_dict.has("type"):
		return
		
	var type = rule_dict.get("type", "string").to_lower()
	match type:
		"string":
			add_string(key, rule_dict.get("options"), rule_dict.get("max_len", -1))
			if rule_dict.has("regex"):
				add_regex(key, rule_dict["regex"])
		"int", "integer":
			add_int(key, rule_dict.get("min"), rule_dict.get("max"))
		"float", "number":
			add_float(key, rule_dict.get("min"), rule_dict.get("max"))
		"bool", "boolean":
			add_bool(key)
		"array":
			add_array(key)
		"dict", "dictionary":
			add_dictionary(key)

## Valida e constrói o dicionário final
func build(data: Dictionary) -> Dictionary:
	var result = {}
	# Se não houver regras, retorna o dado original (comportamento permissivo)
	if _rules.is_empty():
		return data
		
	for key in _rules:
		if not data.has(key):
			push_error("[Auth Kernel] Schema Error: Missing key '%s'" % key)
			return {}
		
		var val = data[key]
		var rule = _rules[key]
		
		if not _validate(val, rule, key):
			return {}
			
		result[key] = val
	return result

func _validate(val: Variant, rule: Dictionary, key: String) -> bool:
	match rule.type:
		Type.STRING:
			if typeof(val) != TYPE_STRING:
				push_error("[Auth Kernel] Schema Error: Key '%s' must be String" % key)
				return false
			if rule.has("options") and not rule.options.is_empty() and not val in rule.options:
				push_error("[Auth Kernel] Schema Error: Key '%s' value '%s' not in allowed options" % [key, val])
				return false
			if rule.get("max_len", -1) != -1 and val.length() > rule.max_len:
				push_error("[Auth Kernel] Schema Error: Key '%s' exceeds max length %d" % [key, rule.max_len])
				return false
			if rule.has("regex"):
				var re = RegEx.new()
				re.compile(rule.regex)
				if not re.search(val):
					push_error("[Auth Kernel] Schema Error: Key '%s' does not match regex pattern" % key)
					return false
		Type.INT:
			if typeof(val) != TYPE_INT and typeof(val) != TYPE_FLOAT:
				push_error("[Auth Kernel] Schema Error: Key '%s' must be Integer" % key)
				return false
			if typeof(val) == TYPE_FLOAT and val != floor(val):
				push_error("[Auth Kernel] Schema Error: Key '%s' must be an Integer (received float with decimals)" % key)
				return false
			if rule.has("min") and val < rule.min:
				push_error("[Auth Kernel] Schema Error: Key '%s' value %s is below minimum %s" % [key, str(val), str(rule.min)])
				return false
			if rule.has("max") and val > rule.max:
				push_error("[Auth Kernel] Schema Error: Key '%s' value %s is above maximum %s" % [key, str(val), str(rule.max)])
				return false
		Type.FLOAT:
			if typeof(val) != TYPE_FLOAT and typeof(val) != TYPE_INT:
				push_error("[Auth Kernel] Schema Error: Key '%s' must be Float or Int" % key)
				return false
			if rule.has("min") and val < rule.min:
				push_error("[Auth Kernel] Schema Error: Key '%s' value %s is below minimum %s" % [key, str(val), str(rule.min)])
				return false
			if rule.has("max") and val > rule.max:
				push_error("[Auth Kernel] Schema Error: Key '%s' value %s is above maximum %s" % [key, str(val), str(rule.max)])
				return false
		Type.BOOL:
			if typeof(val) != TYPE_BOOL:
				push_error("[Auth Kernel] Schema Error: Key '%s' must be Boolean" % key)
				return false
		Type.ARRAY:
			if typeof(val) != TYPE_ARRAY:
				push_error("[Auth Kernel] Schema Error: Key '%s' must be Array" % key)
				return false
		Type.DICTIONARY:
			if typeof(val) != TYPE_DICTIONARY:
				push_error("[Auth Kernel] Schema Error: Key '%s' must be Dictionary" % key)
				return false
	return true
