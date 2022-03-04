New-Item -Path 'C:\ADFTraining' -ItemType Directory
New-Item -Path 'C:\ADFTraining\Eng-list.txt' -ItemType File
Add-Content -Path 'C:\ADFTraining\Eng-list.txt' "EngID, Alias"
Add-Content -Path 'C:\ADFTraining\Eng-list.txt' "`1, tcsougan"
Add-Content -Path 'C:\ADFTraining\Eng-list.txt' "`2, gaking"
Add-Content -Path 'C:\ADFTraining\Eng-list.txt' "`3, Hiten"
Add-Content -Path 'C:\ADFTraining\Eng-list.txt' "`4, Shruti"
New-SmbShare -Name ADF -Path 'C:\ADFTraining' -FullAccess Everyone