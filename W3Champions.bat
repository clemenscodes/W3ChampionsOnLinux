C:
cd C:\Program Files\W3Champions\
start W3Champions.exe
timeout 5
net stop "Bonjour Service"
net start "Bonjour Service"
