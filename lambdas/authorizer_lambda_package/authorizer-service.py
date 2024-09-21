import json
import jwt  # Biblioteca PyJWT
import os

# Chave secreta para verificar o token JWT (deve ser a mesma usada na função de autenticação)
JWT_SECRET = os.environ.get('JWT_SECRET', 'postech70')
JWT_ALGORITHM = 'HS256'

def lambda_handler(event, context):
    token = event.get('authorizationToken', '')
    
    if not token:
        raise Exception('Unauthorized')

    try:
        # Remover o prefixo 'Bearer ' se existir
        if token.startswith('Bearer '):
            token = token[7:]

        # Decodificar e verificar o token JWT
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])

        # Extrair o principal (por exemplo, email do usuário)
        principal_id = payload.get('email', 'user')

        # Obter o ARN do método invocado
        method_arn = event['methodArn']

        # Gerar a política de autorização
        policy_document = generate_policy(principal_id, 'Allow', method_arn)

        return policy_document

    except jwt.ExpiredSignatureError:
        # Token expirado
        raise Exception('Unauthorized')
    except jwt.InvalidTokenError:
        # Token inválido
        raise Exception('Unauthorized')

def generate_policy(principal_id, effect, resource):
    auth_response = {}
    auth_response['principalId'] = principal_id

    if effect and resource:
        policy_document = {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource
                }
            ]
        }
        auth_response['policyDocument'] = policy_document

    # Opcional: adicionar informações de contexto
    auth_response['context'] = {
        'user': principal_id
    }

    return auth_response
