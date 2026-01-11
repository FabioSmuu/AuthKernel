class_name RPCMiddleware
extends RefCounted

## Middleware para interceptar e validar chamadas RPC usando AuthKernel.
## Esta versão é RefCounted, o que significa que não precisa estar na árvore de nós (SceneTree).
## Pode ser instanciada em qualquer script ou usada como uma variável global se armazenada corretamente.

signal unauthorized_rpc(sender_id: int, method: String, args: Array)

var tokens: TokenManager
var enforce_auth: bool = true

func _init(p_secret_key: String = "default_secret"):
	tokens = TokenManager.new(p_secret_key)

func is_authorized(peer_id: int) -> bool:
	if not enforce_auth: return true
	return tokens.is_authorized(peer_id)

## Função para ser chamada antes de executar uma lógica RPC no servidor.
## Como não é um Node, você precisa passar o objeto 'multiplayer' do Godot para acessar o sender_id.
func authenticate_rpc(multiplayer_api: MultiplayerAPI, method: String, args: Array = []) -> bool:
	if not multiplayer_api: return false
	
	var sender_id = multiplayer_api.get_remote_sender_id()
	
	# Localhost / Server
	if sender_id == 0 or sender_id == 1:
		return true
		
	if is_authorized(sender_id):
		return true
	
	unauthorized_rpc.emit(sender_id, method, args)
	return false
