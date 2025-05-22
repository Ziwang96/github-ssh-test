#!/bin/bash

setproperty()
{
    # Defines the property in the Consul KV if the key is undefined.
    #
    # Arguments:
    # 1 - Consul KV property value
    # 2 - Consul KV property URL
    # 3 - Optional boolean that specifies whether the an updated value
    #     should be echoed (defaults to true).
    # Returns
    # N/A

    local key_value=$1
    local key_url=$2
    local echo_is_enabled=true

    if [ $# == 3 ]
    then
       local echo_is_enabled=$3
    fi

    # Note:
    # The ?case=0 flag means to turn the PUT into a Check-And-Set operation,
    # so that the value will only be put if the key does not already exist.

    local was_updated=$(curl -s -X PUT -d "$key_value" $key_url?cas=0)

    if [ true == $echo_is_enabled ] && [ true == $was_updated ]
    then
        echo "ConsulKV[URL=$key_url][value=$key_value]"
    fi

}
readonly -f setproperty


setproperties()
{
    local url="http://localhost:8500"

    local url_config="$url/v1/kv/config"
    local url_application="$url_config/application"
    local url_oauth2="$url_application/oauth2"
    local url_oauth2_adminId="$url_oauth2/adminId"
    local url_oauth2_adminSecret="$url_oauth2/adminSecret"
    local url_oauth2_client_clientId="$url_oauth2/client.clientId"
    local url_oauth2_client_clientSecret="$url_oauth2/client.clientSecret"
    local url_oauth2_client_redirectUri="$url_oauth2/client.redirectUri"
    local url_oauth2_clientId="$url_oauth2/clientId"
    local url_oauth2_clientSecret="$url_oauth2/clientSecret"
    local url_oauth2_jwt_signingKey="$url_oauth2/jwt.signingKey"
  
    setproperty 'sas.admin' $url_oauth2_adminId
    setproperty '${oauth2.client.clientSecret}' $url_oauth2_adminSecret
    setproperty 'sas.${spring.application.name}' $url_oauth2_client_clientId
    setproperty 'Go4thsas' $url_oauth2_client_clientSecret
    setproperty '${server.contextPath:${server.context-path:}}/' $url_oauth2_client_redirectUri
    setproperty '${oauth2.client.clientId}' $url_oauth2_clientId
    setproperty '${oauth2.client.clientSecret}' $url_oauth2_clientSecret
    setproperty 'tokenkey' $url_oauth2_jwt_signingKey
}
readonly -f setproperties

main() 
{
    local url="http://localhost:8500"

    # HTTP response code
    local http_response_code=0

    # timeout in units of seconds to wait for Consul KV to respond
    timeout_sec=120

    # while loop sleep time in units of seconds
    local sleep_time_sec=5

    # URL of the consul health service endpoint
    url_health_service_consul="$url/v1/health/service/consul"

    # wait until Consul is available or max wait exceeded
    while [ 200 -ne $http_response_code ] && [ $SECONDS -lt $timeout_sec ]
    do
        http_response_code=$(curl -w %{response_code} -s --output /dev/null $url_health_service_consul)
        if [ 200 -eq $http_response_code ]
        then
            break
        fi
        sleep $sleep_time_sec
    done

    if [ 200 -eq $http_response_code ]
    then
        # set LDAP properties if not already defined in Consul KV
        setproperties
    else
        echo "Unable to access: $url_health_service_consul"
    fi

}

readonly -f main

is_prompt=true

while [[ $# > 0 ]]
do
key="$1"
case $key in
    -f|--file)
    . $2
    shift
    ;;
    -u|--userdn)
    ldap_connection_userdn=$2
    shift
    ;;
    -c|--credential)
    ldap_connection_password=$2
    shift
    ;;
    -a|--admin)
    identities_administrator=$2
    shift
    ;;
    -i|--interactive)
    is_prompt=$2
    shift
    ;;
    -h|--help)
    usage
    exit 3
    ;;
    *)
    # For invalid arguments, print the usage message.
    usage
    exit 2
    ;;
esac
shift
done

main
