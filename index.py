import os
import boto3
import json

sns_client = boto3.client('sns')

def lambda_handler(event, context):
    zulu_value = os.getenv("zulu")
    sns_topic_arn = os.getenv('sns_topic_arn')

    # Mensaje a enviar
    message = {
        "subject": "Notificación desde Lambda",
        "body": f"Este es un mensaje enviado de parte de {zulu_value}"
    }

    try:
        # Publicar el mensaje en el SNS Topic
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Message=json.dumps(message),
            Subject="Notificación Lambda"
        )
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Notificación enviada con éxito."})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
