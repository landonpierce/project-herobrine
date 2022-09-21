import logging
import uuid
import azure.functions as func
import datetime
import json
from nacl.signing import VerifyKey
from nacl.exceptions import BadSignatureError

def respond_to_discord_interaction():
    ##############################################
    # INSERT CODE TO RESPOND TO DISCORD USER HERE #
    ###############################################

    logging.info("Successfully responded to discord user.")
    return

def verify_signature_headers(headers, data):

    # Your public key can be found on your application in the Developer Portal
    PUBLIC_KEY = 'c7c7fd8e569b3477146fdcdc4785a62840d8410192afa888e372b25c884ae80f'

    verify_key = VerifyKey(bytes.fromhex(PUBLIC_KEY))
    try:
        signature = headers["X-Signature-Ed25519"]
        timestamp = headers["X-Signature-Timestamp"]
    except KeyError:
        return False
    body = data.decode("utf-8")

    try:
        verify_key.verify(f'{timestamp}{body}'.encode(), bytes.fromhex(signature))
        return True
    except BadSignatureError:
        return False

def main(req: func.HttpRequest, outputEvent: func.Out[func.EventGridOutputEvent]) -> func.HttpResponse:
    logging.info(f"Received event from discord to start server.")

    # outputEvent.set(
    #     func.EventGridOutputEvent(
    #         id=str(uuid.uuid4()),
    #         data={},
    #         subject="Minecraft VM",
    #         event_type="start-server",
    #         event_time=datetime.datetime.utcnow(),
    #         data_version="1.0"))

    respond_to_discord_interaction()

    if(verify_signature_headers(req.headers, req.get_body())):
        return func.HttpResponse(json.dumps(
            {
                "type": 4, 
                "data": {
                    "content": "Your server has started:)"
                }
            }
        ), status_code=200, mimetype="application/json")
    else:
        logging.info("Invalid request signature")
        return func.HttpResponse("invalid request signature", status_code=401)
    # return func.HttpResponse("Successfully issued a start server event.", status_code=202)

