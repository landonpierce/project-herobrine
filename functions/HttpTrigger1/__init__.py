import logging
import uuid
import azure.functions as func
import datetime

def main(req: func.HttpRequest, 
        outputEvent: func.Out[func.EventGridOutputEvent]) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    outputEvent.set(
        func.EventGridOutputEvent(
            id=str(uuid.uuid4()),
            data={},
            subject="MC VM",
            event_type="start-server",
            event_time=datetime.datetime.utcnow(),
            data_version="1.0"))
    return func.HttpResponse(

        "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
        status_code=200
    )
