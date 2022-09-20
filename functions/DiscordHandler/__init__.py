import logging
import uuid
import azure.functions as func
import datetime

def respond_to_discord_interaction():
    ##############################################
    # INSERT CODE TO RESPOND TO DISCORD USER HERE #
    ###############################################

    logging.info("Successfully responded to discord user.")
    return



def main(req: func.HttpRequest, outputEvent: func.Out[func.EventGridOutputEvent]) -> func.HttpResponse:
    logging.info(f"Received event from discord to start server.")

    outputEvent.set(
        func.EventGridOutputEvent(
            id=str(uuid.uuid4()),
            data={},
            subject="Minecraft VM",
            event_type="start-server",
            event_time=datetime.datetime.utcnow(),
            data_version="1.0"))

    respond_to_discord_interaction()

    return func.HttpResponse("Successfully issued a start server event.", status_code=202)
