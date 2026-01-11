extends SceneTree

## Exemplo de RPC Middleware Profissional
## Seguindo o padrão de injeção de classe e separação de tokens.

func _init():
	var AuthKernel = load("res://addons/auth_kernel/scripts/kernel.gd")
	var RPCMiddleware = load("res://addons/auth_kernel/scripts/middleware/rpc_middleware.gd")
	var RPCBase = load("res://addons/auth_kernel/scripts/middleware/rpc_base.gd")
	
	var secret = "minha_chave_secreta"
	
	# 1. MIDDLEWARE E TOKENS (SISTEMA SEPARADO)
	var middleware = RPCMiddleware.new(secret)
	
	# 2. INJEÇÃO NA CLASSE RPC
	# Simulamos um nó de jogo que estende RPCBase
	var player_rpc = RPCBase.new(middleware)
	
	# 3. SIMULAÇÃO DE FLUXO
	print("--- Teste RPC ---")
	
	var peer_id = 123
	var token = AuthKernel.create_token_from_dict(
		{"alg": "HS256"}, {"user_id": 1},
		{"alg": "string"}, {"user_id": "int"},
		AuthKernel.hmac256_sign.bind(secret)
	)
	
	# Teste sem autorização
	print("Autorizado (Peer %d) antes do token? " % peer_id, middleware.is_authorized(peer_id))
	
	# Registro do token no sistema separado
	middleware.tokens.register_peer(peer_id, token)
	print("Autorizado (Peer %d) após registro? " % peer_id, middleware.is_authorized(peer_id))
	
	# Exemplo de uso dentro de uma função (Simulado)
	# if not player_rpc.auth("matar_inimigo"): return
	
	print("Sucesso: Estrutura de injeção e tokens validada.")
	quit()
