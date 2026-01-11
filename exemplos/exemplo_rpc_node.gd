extends SceneTree

## Exemplo de RPC Node com Middleware Injetada
## Demonstra como um nó de jogo usaria a classe injetada seguindo um padrão profissional.

func _init():
	var RPCMiddleware = load("res://addons/auth_kernel/scripts/middleware/rpc_middleware.gd")
	
	# 1. SETUP (Poderia ser um Autoload/Singleton)
	var middleware = RPCMiddleware.new("secret_123")
	
	# 2. INSTÂNCIA DO NÓ COM INJEÇÃO
	# Criamos o nó e injetamos a middleware diretamente
	var game_node = GameActionNode.new(middleware)
	
	print("--- Teste de Nó RPC Injetado ---")
	print("Nó: ", game_node.name)
	print("Middleware injetada com sucesso: ", game_node.middleware != null)
	
	# No mundo real, a proteção seria ativada via RPC:
	# game_node.executar_acao_protegida.rpc("ataque")
	
	quit()

# Classe interna para simular um nó de jogo real que estende a nossa nova RPCBase
class GameActionNode extends RPCBase:
	func _init(p_middleware):
		super(p_middleware)
		self.name = "GameActionNode"
	
	@rpc("any_peer")
	func executar_acao_protegida(acao: String):
		# PROTEÇÃO PROFISSIONAL: Apenas uma linha injetada via classe base
		if not auth("executar_acao_protegida"): return
		
		print("Executando ação: ", acao)
