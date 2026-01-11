extends SceneTree

func _init():
	var AuthKernel = load("res://addons/auth_kernel/scripts/kernel.gd")
	#var AuthSchema = load("res://addons/auth_kernel/scripts/schema.gd")
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

	# 2. REGRAS (SCHEMA) VIA CÓDIGO
	var p_schema = AuthSchema.new()\
		.int("id", 1, 1000)\
		.string("user", null, 32)\
		.regex("email", "^.+@.+$")\
		.bool("active")\
		.array("tags")\
		.dictionary("meta") # p_schema.dictionary("meta")
		
	var h_schema = AuthSchema.new().string("alg", ["HS256"])

	# 3. ASSINATURA
	var sign_func = func(data): return AuthKernel.hmac256_sign(data, secret)
	var verify_func = func(data, sig): return AuthKernel.hmac256_verify(data, sig, secret)

	# 4. CRIAR TOKEN
	var token = AuthKernel.create_token({"alg":"HS256"}, payload_data, h_schema, p_schema, sign_func)
	print("Token: ", token)
	
	# 5. VALIDAR E DECODIFICAR
	if AuthKernel.verify_token(token, verify_func):
		# var result = AuthKernel.decode_header(token, h_schema)
		var result = AuthKernel.decode_payload(token, p_schema)
		print("Sucesso (Schema): ", result)
	
	quit()
