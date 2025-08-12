# Set location for AppHost lookup
[ -z "$DOTNET_ROOT" ] && export DOTNET_ROOT=/usr/lib/dotnet

# Opt out of telemetry by default
[ -z "$DOTNET_CLI_TELEMETRY_OPTOUT" ] && export DOTNET_CLI_TELEMETRY_OPTOUT=1
