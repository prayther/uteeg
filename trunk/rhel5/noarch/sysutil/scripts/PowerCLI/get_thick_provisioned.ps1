# for each build a bunch of vm’s based on the csv file
clear
Connect-VIServer -server C2E-VCenter -user aprayther -password qweQWE123!@#123
$v = Get-Datacenter NCES | Get-VM *

Get-HardDisk -VM $v | where {$_.StorageFormat -match "Thick"}