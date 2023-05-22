import os
import requests
import subprocess
import shlex
from pathlib import Path
from fcntl import fcntl, F_GETFL, F_SETFL

from .orchestrationApi import OrchestrationApi
from .load_history import LoadHistory
from .servicebusReceiver import ServicebusReceiver

from azure.identity import DefaultAzureCredential

def __runShellCommand(dbt_command: str) -> int :
    print(os.path.dirname(os.path.realpath(__file__)))
    workingDirectory = os.path.join(Path(os.path.dirname(os.path.realpath(__file__))).parent.absolute(), "dbt")
    print(workingDirectory)
    arguments = ['dbt']
    arguments.extend(shlex.split(dbt_command))
    process = subprocess.Popen(arguments,
                     cwd=workingDirectory,
                     stdout=subprocess.PIPE, 
                     stderr=subprocess.PIPE,
                     universal_newlines=True)
    
    # set the O_NONBLOCK flag of p.stdout file descriptor:
    flagsOut = fcntl(process.stdout, F_GETFL) # get current p.stdout flags
    fcntl(process.stdout, F_SETFL, flagsOut | os.O_NONBLOCK)

    flagsErr = fcntl(process.stderr, F_GETFL) # get current p.stdout flags
    fcntl(process.stderr, F_SETFL, flagsErr | os.O_NONBLOCK)

    return_code = None   
    while return_code is None:
        output = process.stdout.readline()
        if output:
            print(f'DBT output: {output.strip()}')
        
        stderr = process.stderr.readline()
        if stderr:
            print(f'DBT stderr: {stderr.strip()}')
        
        return_code = process.poll()
        if return_code is not None:
            print('RETURN CODE', return_code)
            # Process has finished, read rest of the output 
            for output in process.stdout.readlines():
                if output:
                    print(f'DBT output: {output.strip()}')

            for err in process.stderr.readlines():
                if err:
                    print(f'DBT err: {err.strip()}')
    return return_code

if __name__ == "__main__":
    try:
        print("Begining")
        credential = DefaultAzureCredential()
        orchestrationApi = OrchestrationApi()
        
        print("Getting Service Bus message")
        servicebusReceiver = ServicebusReceiver()
        
        sb_message = servicebusReceiver.receive_message(credential)
        if sb_message:
            print(f'Product : {sb_message.product_name}')

            if sb_message.dbt_command:
                print(f'Executing dbt command: {sb_message.dbt_command}')
                return_code = __runShellCommand(sb_message.dbt_command)
                if return_code and return_code != 0:
                    print("DBT finsihed with error code. Updating table status to error")
                    orchestrationApi.update_product_history(LoadHistory(sb_message.product_name, "failed", sb_message.ldts))
                    servicebusReceiver.dead_letter()
                else:
                    print("Updating table status to finished")
                    orchestrationApi.update_product_history(LoadHistory(sb_message.product_name, "succeeded", sb_message.ldts))
                    servicebusReceiver.complete_message()
            else:
                raise ValueError("dbt_command is missing")
        else:
            print("No message in queue so we stop here")
    except requests.exceptions.HTTPError as error:
        print(f"Api error: {error}")
        if orchestrationApi and sb_message:
            orchestrationApi.update_product_history(LoadHistory(sb_message.product_name, "failed", sb_message.ldts))
        if servicebusReceiver:
            servicebusReceiver.dead_letter()
    except Exception as err:
        print(f"Unexpected DBT error for {err=}, {type(err)=}")
        if orchestrationApi and sb_message:
            orchestrationApi.update_product_history(LoadHistory(sb_message.product_name, "failed", sb_message.ldts))
        if servicebusReceiver:
            servicebusReceiver.dead_letter()

