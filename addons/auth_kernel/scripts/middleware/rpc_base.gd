class_name RPCBase
extends Node # Felizmente é preciso usar Node para evitar a inserção do MultiplayerAPI hehe.

## Classe base profissional para injeção de RPC Middleware.
## Permite proteger métodos RPC com uma única chamada.

var middleware: RPCMiddleware

func _init(p_middleware: RPCMiddleware = null):
	self.middleware = p_middleware

## Valida se o remetente da chamada RPC atual está autorizado.
func auth(method_name: String = "unknown") -> bool:
	if not middleware:
		push_error("[RPCBase] Middleware not injected into the node: %s" % name)
		return false
	
	return middleware.authenticate_rpc(multiplayer, method_name)
