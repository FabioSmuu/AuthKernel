extends SceneTree

func _init():
	var AuthKernel = load("res://addons/auth_kernel/scripts/kernel.gd")
	var secret = "SENHA_DA_JWT"
	
	# 1. DADOS
	var payload_data = {
		"id": 7,
		"user": "FabioSmuu",
		"email": "fabiosmuu@gmail.com",
		"active": true,
		"tags": ["godot", "jwt"],
		"meta": {"level": 1337}
	}

	# 2. REGRAS (SCHEMA) VIA DICIONÁRIO
	var payload_def = {
		"id": "int",
		"user": {"type": "string", "max_len": 20},
		"email": {"type": "string", "regex": "^.+@.+$"},
		"active": "bool",
		"tags": "array",
		"meta": "dictionary"
	}
	
	# 3. ASSINATURA
	var sign_func = func(data): return AuthKernel.hmac256_sign(data, secret)
	var verify_func = func(data, sig): return AuthKernel.hmac256_verify(data, sig, secret)

	# 4. CRIAR TOKEN
	var token = AuthKernel.create_token_from_dict({"alg":"HS256"}, payload_data, {"alg":"string"}, payload_def, sign_func)
	print("Token: ", token)
	
	# 5. VALIDAR E DECODIFICAR
	if AuthKernel.verify_token(token, verify_func):
		# var result = AuthKernel.decode_header(token, {"alg":"string"})
		var result = AuthKernel.decode_payload(token, payload_def)
		print("Sucesso (Dict): ", result)
	
	quit()
