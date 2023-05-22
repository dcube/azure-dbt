import os

from azure.servicebus import AutoLockRenewer,ServiceBusClient
from azure.servicebus.exceptions import MessageAlreadySettled

from .serviceBusMessage import ServiceBusMessage

class ServicebusReceiver:
    def __init__(self):
        print("Getting Service Bus settings")
        service_bus_name = os.environ['SB_NAMESPACE']
        self.queue_name = os.environ['SB_QUEUE_NAME']
        self.fully_qualified_namespace= f'{service_bus_name}.servicebus.windows.net'
        self.is_closed = False

    def receive_message(self, credential: object) -> ServiceBusMessage:
        self.client = ServiceBusClient(self.fully_qualified_namespace, credential)
        # max_wait_time specifies how long the receiver should wait with no incoming messages before stopping receipt.
        # Default is None; to receive forever.
        a_day = 24*60*60
        lock_renewal = AutoLockRenewer(max_lock_renewal_duration=a_day, on_lock_renew_failure=self.on_renew_error)
        self.receiver = self.client.get_queue_receiver(self.queue_name, max_wait_time=30, auto_lock_renewer=lock_renewal)
        received_message = self.receiver.receive_messages(max_message_count=1, max_wait_time=10)  # try to receive a single in a batch within 10 seconds
        if received_message:
            # https://learn.microsoft.com/en-us/python/api/azure-servicebus/azure.servicebus.autolockrenewer?view=azure-python
            self.message = received_message[0]
            print(str(self.message))
            return ServiceBusMessage.from_json(str(self.message))
        else:
            print("No message")
            result = None
        return result
    
    def complete_message(self):
        print("complete_message")
        if self.receiver and not self.is_closed:
            self.receiver.complete_message(self.message)
            self.receiver.close()
            self.client.close()
        self.is_closed = True

    def dead_letter(self):
        print("dead_letter")
        if self.receiver and not self.is_closed:
            self.receiver.dead_letter_message(self.message)
            self.receiver.close()
            self.client.close()
        self.is_closed = True

    async def on_renew_error(renewable, error, _):
        print("On renew error -\n renewable: ", renewable,"\n error: ", error,"\n type: ", type(error), "\n message: ", error.message)
        if type(error) == MessageAlreadySettled:
            print("Message already settled")
        else:
            print("Error renewing lock: %s", error)