FROM ghcr.io/dbt-labs/dbt-snowflake:1.3.latest

# Install AZ CLI
RUN apt-get update && apt-get install -y curl
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

ARG DBT_PROJECT_PATH=dbt_src
ARG TOOLS_PATH=.

#copy DBT project
COPY $DBT_PROJECT_PATH /dbt

#copy startup file
COPY $TOOLS_PATH/entrypoint.sh /dbt
RUN chmod +x /dbt/entrypoint.sh

#copy python application
COPY $TOOLS_PATH/python_launcher /python_launcher

# install python packages
RUN pip install -r /python_launcher/requirements.txt

#WORKDIR /dbt
WORKDIR /

# Run dbt
ENTRYPOINT ["/dbt/entrypoint.sh"]
