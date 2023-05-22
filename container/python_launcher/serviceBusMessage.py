from dataclasses import dataclass
from datetime import datetime
import json

@dataclass
class ServiceBusMessage():
    product_name: str
    ldts: datetime
    dbt_command: str

    @staticmethod
    def from_json(str: str):
        json_dct = json.loads(str)
        return ServiceBusMessage(json_dct['product_name'],
                                 json_dct['ldts'],
                                 json_dct['dbt_command'])