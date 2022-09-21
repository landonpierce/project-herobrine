import json
import logging
import azure.functions as func
import os
from azure.mgmt.resource import ResourceManagementClient
from azure.identity import DefaultAzureCredential

def create_resource_group():
    # Acquire a credential object using CLI-based authentication.
    credential = DefaultAzureCredential(exclude_visual_studio_code_credential=True)

    # Retrieve subscription ID from environment variable.
    subscription_id = os.environ["AZURE_SUBSCRIPTION_ID"]

    # Obtain the management object for resources.
    resource_client = ResourceManagementClient(credential, subscription_id)

    # Provision the resource group.
    rg_result = resource_client.resource_groups.create_or_update(
        "PythonAzureExample-rg",
        {
            "location": "eastus"
        }
    )


def main(event: func.EventGridEvent):
    eventData = json.dumps({
        'id': event.id,
        'data': event.get_json(),
        'topic': event.topic,
        'subject': event.subject,
        'event_type': event.event_type,
    })

    create_resource_group()
