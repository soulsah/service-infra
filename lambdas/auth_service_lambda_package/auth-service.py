import boto3
import json
import jwt  # Biblioteca para trabalhar com JWT
import os

# Chave secreta para assinar o token JWT (armazene-a de forma segura)
JWT_SECRET = os.environ.get('JWT_SECRET', 'postech70')
JWT_ALGORITHM = 'HS256'  # Algoritmo de assinatura do JWT

def consulta_email_senha(email, senha):
    dynamodb = boto3.resource('dynamodb')
    tabela = dynamodb.Table('Cliente')

    # Consultar o item baseado no email
    resposta = tabela.get_item(
        Key={
            'email': email
        }
    )

    # Verificar se o item existe e se a senha está correta
    if 'Item' in resposta and resposta['Item'].get('senha') == senha:
        return True
    else:
        return False

def lambda_handler(event, context):
    email = event.get('email', '')
    senha = event.get('senha', '')

    if consulta_email_senha(email, senha):
        # Gerar o token JWT
        token = jwt.encode({'email': email}, JWT_SECRET, algorithm=JWT_ALGORITHM)

        return {
            'statusCode': 200,
            'body': json.dumps({"token": token})
        }
    else:
        return {
            'statusCode': 403,
            'body': json.dumps('Email ou senha incorretos')
        }
