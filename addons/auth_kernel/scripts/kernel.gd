class_name AuthKernel
extends RefCounted

const AuthSchema = preload("res://addons/auth_kernel/scripts/schema.gd")

# Função utilitária para Base64URL (sem +, / ou =)
static func base64_url_encode(data: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(data).replace("+", "-").replace("/", "_").replace("=", "")

static func base64_url_decode(base64_str: String) -> PackedByteArray:
	var pad_len = (4 - (base64_str.length() % 4)) % 4
	base64_str += "====".substr(0, pad_len)
	return Marshalls.base64_to_raw(base64_str.replace("-", "+").replace("_", "/"))

## Cria um token JWT baseado em schemas de header e payload.
## A assinatura é feita externamente via callable para flexibilidade.
static func create_token(header_data: Dictionary, payload_data: Dictionary, header_schema: AuthSchema, payload_schema: AuthSchema, sign_func: Callable) -> String:
	var validated_header = header_schema.build(header_data)
	var validated_payload = payload_schema.build(payload_data)
	
	if validated_header.is_empty() or validated_payload.is_empty():
		push_error("[Auth Kernel] Creation Error: Schema validation failed.")
		return ""
		
	var header_json = JSON.stringify(validated_header)
	var payload_json = JSON.stringify(validated_payload)
	
	var header_b64 = base64_url_encode(header_json.to_utf8_buffer())
	var payload_b64 = base64_url_encode(payload_json.to_utf8_buffer())
	
	var data_to_sign = header_b64 + "." + payload_b64
	var signature = sign_func.call(data_to_sign)
	
	if not signature is String:
		push_error("[Auth Kernel] Creation Error: sign_func must return a String (base64url signature).")
		return ""
		
	return data_to_sign + "." + signature

## Cria um token JWT usando definições de schema em formato de dicionário.
static func create_token_from_dict(header_data: Dictionary, payload_data: Dictionary, header_def: Dictionary, payload_def: Dictionary, sign_func: Callable) -> String:
	var h_schema = AuthSchema.new().from_dict(header_def)
	var p_schema = AuthSchema.new().from_dict(payload_def)
	return create_token(header_data, payload_data, h_schema, p_schema, sign_func)

## Verifica a integridade do token comparando a assinatura.
static func verify_token(token: String, verify_func: Callable) -> bool:
	if token.is_empty():
		return false
		
	var parts = token.split(".")
	if parts.size() != 3:
		return false
		
	var header_b64 = parts[0]
	var payload_b64 = parts[1]
	var signature = parts[2]
	
	var data_to_verify = header_b64 + "." + payload_b64
	return verify_func.call(data_to_verify, signature)

## Compara duas strings em tempo constante para evitar timing attacks.
static func secure_compare(a: String, b: String) -> bool:
	if a.length() != b.length():
		return false
	
	var result = 0
	var a_bytes = a.to_utf8_buffer()
	var b_bytes = b.to_utf8_buffer()
	
	for i in range(a_bytes.size()):
		result |= a_bytes[i] ^ b_bytes[i]
		
	return result == 0

## Atalho para criar uma assinatura HMAC-SHA256 padrão (Base64URL)
static func hmac256_sign(data: String, key: String) -> String:
	var crypto = Crypto.new()
	var key_bytes = key.to_utf8_buffer()
	var data_bytes = data.to_utf8_buffer()
	var signature = crypto.hmac_digest(HashingContext.HASH_SHA256, key_bytes, data_bytes)
	return base64_url_encode(signature)

## Atalho para verificar uma assinatura HMAC-SHA256 padrão
static func hmac256_verify(data: String, signature: String, key: String) -> bool:
	var expected = hmac256_sign(data, key)
	return secure_compare(signature, expected)

## Decodifica uma parte do token pelo índice (0: header, 1: payload)
## O parâmetro 'schema_or_dict' pode ser uma instância de AuthSchema ou um Dictionary de definição.
static func decode_by_index(token: String, index: int, schema_or_dict: Variant = null) -> Dictionary:
	var parts = token.split(".")
	if parts.size() <= index:
		return {}
		
	var json_bytes = base64_url_decode(parts[index])
	var json_str = json_bytes.get_string_from_utf8()
	
	var json = JSON.new()
	var error = json.parse(json_str)
	if error != OK:
		return {}
		
	var data = json.data
	if not data is Dictionary:
		return {}
		
	if schema_or_dict == null:
		return data
		
	var final_schema: AuthSchema
	if schema_or_dict is AuthSchema:
		final_schema = schema_or_dict
	elif typeof(schema_or_dict) == TYPE_DICTIONARY:
		# Se o dicionário passado não parecer um schema (ex: não tem chaves de tipo), 
		# ou se for o próprio dado, retornamos o dado puro para evitar erros de validação.
		# Um schema válido via dict deve ter strings como valores ou dicts com a chave 'type'.
		# comentário pra mim no esquecer hehe.
		var is_likely_schema = false
		for k in schema_or_dict:
			var v = schema_or_dict[k]
			if typeof(v) == TYPE_STRING or (typeof(v) == TYPE_DICTIONARY and v.has("type")):
				is_likely_schema = true
				break
		
		if not is_likely_schema:
			return data
			
		final_schema = AuthSchema.new().from_dict(schema_or_dict)
	else:
		return data
		
	return final_schema.build(data)

static func decode_header(token: String, schema_or_dict: Variant = null) -> Dictionary:
	return decode_by_index(token, 0, schema_or_dict)

static func decode_payload(token: String, schema_or_dict: Variant = null) -> Dictionary:
	return decode_by_index(token, 1, schema_or_dict)
