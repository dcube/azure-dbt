from dataclasses import dataclass
from datetime import datetime, date
import json

@dataclass
class LoadHistory:
    product_name: str
    status: str
    ldts: datetime

    def __default(self, obj):
        if isinstance(obj, (date, datetime)):
            return obj.isoformat()
        else:
            return obj.__dict__

    def to_json(self):
        return json.dumps(self, default=self.__default)
    
    @staticmethod
    def from_json(str):
        json_dct = json.loads(str)
        return LoadHistory(json_dct['product_name'],
                            json_dct['status'],
                            json_dct['ldts'])