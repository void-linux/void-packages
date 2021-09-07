# Set location for AppHost lookup
[ -z "$DOTNET_ROOT" ] && export DOTNET_ROOT=/usr/lib/dotnet

# Add dotnet tools directory to PATH
DOTNET_TOOLS_PATH="$HOME/.dotnet/tools"
case "$PATH" in
    *"$DOTNET_TOOLS_PATH"* ) true ;;
    * ) PATH="$PATH:$DOTNET_TOOLS_PATH" ;;
esac
