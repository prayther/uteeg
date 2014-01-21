# for each build a bunch of vm’s based on the csv file
clear
Connect-VIServer -server 150.125.72.134 -user ges\aprayther -password 'P@$$w0rdP@$$w0rd'
Connect-VIServer -server 150.125.75.15 -user ges\aprayther -password 'P@$$w0rdP@$$w0rd'

$blade = "150.125.72.11"

# Connect-VIServer -server C2E-VCenter
$strAffectedCluster = "aarontst"

##Get-View -ViewType VirtualMachine -SearchRoot (Get-Cluster $strAffectedCluster | Get-View).MoRef -Filter @{"Name" = "ges-placeholder-sb-done"}

$vmsremove = GET-VM -Name ges-sim-vma-blab

Remove-VM -VM $vmsremove
#Remove-VM -VM ges-sim-vma-blab

#cd vmstores:\150.125.72.134@443\GES51\test1\ges-sim-vma-blab\
#$vmxfile = Get-Item *.vmx
#echo $vmxfile
#New-VM -vmhost $blade -VMFilePath [test1] $vmsremovevm/$vmsremovevm.vmx
New-VM -vmhost $blade -VMFilePath '[test1] ges-sim-vma-blab/ges-sim-vma-blab.vmx'

#8. Feb 7, 2013 1:12 PM   in response to: virtshak
#Re: remove-vm doesn't delete from inventory
#I see. It looks as if you have these VMs with the same name in different datacenters.
#You can also use a Get-Datacenter -Name <dcname> on the Location parameter of the Get-VM.
#That way only that specific VM gets removed (and unregistered).
#Something like this
# 
#$vmlist = ("vm1", "vm-2", "vm-3")
#$dcName = "MyDC"
#
#foreach ($vmname in $vmlist)
#{
#  $vm = GET-VM -Name $vmname -Location (Get-Datacenter -Name $dcName)
#  if($vm.PowerState -ne "PoweredOff")
#  {
#    Stop-VM -VM $vm
#    Write-output "$vmname shutting down" (get-date)
#  }
#  Remove-VM $vm -DeleteFromDisk:$true
#}