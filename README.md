# AuthKernel
[![License: MIT](https://img.shields.io/badge/License-MIT-%236B7280.svg)](https://opensource.org/licenses/MIT)
[![Godot Version](https://img.shields.io/badge/Godot-%3E=4.0-blue.svg)](https://godotengine.org)

> AuthKernel é um addon para Godot 4.x focado em autenticação segura baseada em JSON Web Tokens (JWT). O sistema foi projetado para ser leve, modular e altamente flexível, permitindo que desenvolvedores implementem camadas de segurança robustas em seus jogos e aplicações.

## Características Principais

*   **Autenticação JWT**: Implementação completa de criação, decodificação e verificação de tokens.
*   **Sistema de Schemas**: Validação de dados inspirada em bibliotecas como Zod, garantindo que o Header e o Payload contenham exatamente o que é esperado.
*   **Middleware RPC**: Integração opcional para proteger chamadas remotas em sistemas multiplayer.
*   **Assinatura Flexível**: Embora utilize HMAC-SHA256 por padrão, o sistema permite a injeção de qualquer algoritmo de assinatura customizado.
*   **Segurança**: Inclui funções para comparação de strings em tempo constante, prevenindo ataques de temporização (timing attacks).

## Instalação

1.  Baixe o conteúdo do repositório.
2.  Copie a pasta `addons/auth_kernel` para dentro do diretório `res://addons/` do seu projeto Godot.
3.  Ative o plugin em **Project Settings > Plugins**.

## Uso Básico

Usando a classe `AuthKernel`. Veja um exemplo usando sem o uso de schemas:

```gdscript
var secret = "sua_chave_secreta"

# Definição de Schemas (Estilo Dicionário)
var header_def = {"alg": "string", "typ": "string"}
var payload_def = {"user_id": "int", "username": "string", "admin": "bool"}

# Dados
var header_data = {"alg": "HS256", "typ": "JWT"}
var payload_data = {"user_id": 1, "username": "Fábio", "admin": true}

# Criação do Token
var token = AuthKernel.create_token_from_dict(
    header_data, 
    payload_data, 
    header_def, 
    payload_def, 
    AuthKernel.hmac256_sign.bind(secret)
)

# Verificação do Token
var is_valid = AuthKernel.verify_token(token, AuthKernel.hmac256_verify.bind(secret))
```

## Versatilidade de Assinatura

Uma das maiores vantagens do AuthKernel é a liberdade de definir como os tokens são assinados. Você não está limitado ao HMAC-SHA256. É possível utilizar qualquer método, como Argon2id, RSA ou até mesmo um sistema simples de Salt customizado.

### Exemplo: Assinatura Customizada com Salt

```gdscript
# Função de assinatura genérica customizada
func minha_assinatura_custom(data: String) -> String:
    var salt = "meu_salt_extra_seguro"
    var combined = data + salt
    var hash = combined.sha256_text() # Exemplo simples usando SHA256 nativo
    return AuthKernel.base64_url_encode(hash.to_utf8_buffer())

# Função de verificação correspondente
func minha_verificacao_custom(data: String, signature: String) -> bool:
    var expected = minha_assinatura_custom(data)
    return AuthKernel.secure_compare(signature, expected)

# Utilizando no Kernel
var token = AuthKernel.create_token(h_data, p_data, h_schema, p_schema, minha_assinatura_custom)
var valid = AuthKernel.verify_token(token, minha_verificacao_custom)
```

## Middleware RPC

O addon inclui um `RPCMiddleware` que facilita a proteção de funções multiplayer. Ele gerencia o estado de autorização dos peers conectados.

```gdscript
# No Servidor
var middleware = RPCMiddleware.new("chave_secreta")

func _on_peer_connected(id):
    # O peer deve enviar o token para ser registrado
    middleware.tokens.register_peer(id, token_recebido)

@rpc
func acao_sensivel():
    if not middleware.authenticate_rpc(multiplayer, "acao_sensivel"):
        return # Chamada não autorizada
    
    # Lógica protegida aqui
```

## Exemplos Práticos

O projeto conta com diversos exemplos na pasta [`exemplos/`](/exemplos). Para testá-los rapidamente sem abrir a interface do Godot, utilize o terminal:

```bash
# Executar exemplo de Schema
godot --headless -s exemplos/exemplo_schema.gd

# Executar exemplo de Dicionário
godot --headless -s exemplos/exemplo_dictionary.gd

# Executar exemplo de RPC
godot --headless -s exemplos/exemplo_rpc.gd
```

## Estrutura de Arquivos
*   [`addons/auth_kernel/scripts/kernel.gd`](/addons/auth_kernel/scripts/kernel.gd): Lógica central do JWT.
*   [`addons/auth_kernel/scripts/schema.gd`](/addons/auth_kernel/scripts/schema.gd): Motor de validação de dados.
*   [`addons/auth_kernel/scripts/middleware/rpc_middleware.gd`](/addons/auth_kernel/scripts/middleware/rpc_middleware.gd): Interceptador para chamadas RPC.
*   [`addons/auth_kernel/scripts/middleware/token_manager.gd`](/addons/auth_kernel/scripts/middleware/token_manager.gd): Gerenciador de sessões e tokens.

Este projeto foi desenvolvido para ser uma base sólida para qualquer sistema de autenticação em Godot, mantendo a simplicidade sem sacrificar a segurança.

**Obrigado pela sua atenção!**