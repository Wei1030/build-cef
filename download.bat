@echo on
powershell -Command "Invoke-WebRequest -Uri 'https://storage.googleapis.com/chrome-infra/depot_tools.zip' -OutFile '.\depot_tools.zip'"
powershell -Command "Expand-Archive -Path '.\depot_tools.zip' -DestinationPath '.\depot_tools' -Force"
del /F /Q .\depot_tools.zip
mkdir .\automate
powershell -Command "Invoke-WebRequest -Uri 'https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py' -OutFile '.\automate\automate-git.py'"
