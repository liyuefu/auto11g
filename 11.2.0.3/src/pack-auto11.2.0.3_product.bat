set SOFT_PATH=auto11g_product_11.2.0.3
echo %SOFT_PATH%
set today="%date:~0,4%-%date:~5,2%-%date:~8,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%"

cd %SOFT_PATH% 
"C:\Program Files\7-Zip\7z.exe" a -r -tzip ..\%SOFT_PATH%_%today%.zip *.*
Rem cd ..
Rem copy %SOFT_PATH%_%today%.zip D:\11grac_software
