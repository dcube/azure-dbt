import os
import requests
import json

from .load_history import LoadHistory

class OrchestrationApi:
    def __init__(self) -> any:
        self.function_url = os.getenv('FUNCTION_URL')
        self.function_key = os.getenv('FUNCTION_KEY')

    def update_product_history(self, loadHistory: LoadHistory):
        data=json.loads(loadHistory.to_json())
        print(f"Update API: {data}")
        headers = {"x-functions-key": self.function_key}
        response = requests.put(f"https://{self.function_url}/api/load", headers=headers, json=data)
        response.raise_for_status()