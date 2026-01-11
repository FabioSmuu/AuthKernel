class_name TokenManager
extends RefCounted

## Gerenciador de tokens separado para uma arquitetura mais limpa. (eu estava com tempo kkk)

var secret_key: String = ""
var _peer_tokens: Dictionary = {}

func _init(p_secret_key: String):
	self.secret_key = p_secret_key

func register_peer(peer_id: int, token: String) -> bool:
	if AuthKernel.verify_token(token, AuthKernel.hmac256_verify.bind(secret_key)):
		_peer_tokens[peer_id] = token
		return true
	return false

func unregister_peer(peer_id: int):
	_peer_tokens.erase(peer_id)

func is_authorized(peer_id: int) -> bool:
	if not _peer_tokens.has(peer_id):
		return false
	
	var token = _peer_tokens[peer_id]
	return AuthKernel.verify_token(token, AuthKernel.hmac256_verify.bind(secret_key))

func get_token(peer_id: int) -> String:
	return _peer_tokens.get(peer_id, "")
