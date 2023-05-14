if which dotnet &> /dev/null
then

    # Ensure dotnet tools are loaded properly
    if ! grep -Fxq "export PATH=\"\$PATH:$HOME/.dotnet/tools\"" ~/.zprofile; then
        echo 'Adding .dotnet/tools to path in ~/.zprofile...'
        echo "export PATH=\"\$PATH:$HOME/.dotnet/tools\"" >> ~/.zprofile
    fi

    # Check if csharprepl is installed
    if ! which csharprepl &> /dev/null; then
        echo "csharprepl is not installed. Now installing..."
        dotnet tool install -g csharprepl
    fi

else
    echo ".NET SDK is not installed. Skipping dotnet.zshrc ..."
fi