# for each build a bunch of vm’s based on the csv file
clear
Connect-VIServer -server C2E-VCenter -user aprayther -password qweQWE123!@#123
# Connect-VIServer -server C2E-VCenter

$satellite = "nces-sb-vm-02.chs.spawar.navy.mil"

foreach ( $newvirtualmachine in get-content E:\steel_sa\trunk\rhel5\noarch\sysutil\scripts\PowerCLI\config-1-hosts.txt )
# hostname,macaddress,ipaddress,resourcepool,folder,vmhostserver,drivesize,memoryrequired,datastorename,notesforvm,guestostype,networkname,projectname,numbercpu,diskstorageformat,swap,root,var,varlog,varlogaudit,home,opt,data,usr,tmp
# hostname,macaddress,ipaddress,resourcepool,folder,vmhostserver,drivesize,memoryrequired,datastorename,notesforvm,guestostype,networkname,projectname,numbercpu,diskstorageformat,2048,1024,2048,1024,1024,512,1024,512,2048,1024
   	 {
   	  $hostname = $newvirtualmachine | %{$_.split(',')[0]}
   	  $macaddress = $newvirtualmachine | %{$_.split(',')[1]}
   	  $ipaddress = $newvirtualmachine | %{$_.split(',')[2]}
   	  $resourcepoolforvm = $newvirtualmachine | %{$_.split(',')[3]}
   	  $folderforvm = $newvirtualmachine | %{$_.split(',')[4]}
   	  $vmhostserver = $newvirtualmachine | %{$_.split(',')[5]}
   	  $drivesize = $newvirtualmachine | %{$_.split(',')[6]}
   	  $memoryrequired = $newvirtualmachine | %{$_.split(',')[7]}
   	  $datastorename = $newvirtualmachine | %{$_.split(',')[8]}
   	  $notesforvm = $newvirtualmachine | %{$_.split(',')[9]}
   	  $guestostype = $newvirtualmachine | %{$_.split(',')[10]}
   	  $networkname = $newvirtualmachine | %{$_.split(',')[11]}
   	  $projectname = $newvirtualmachine | %{$_.split(',')[12]}
	  $numbercpu = $newvirtualmachine | %{$_.split(',')[13]}
	  $diskstorageformat = $newvirtualmachine | %{$_.split(',')[14]}
	  $swap = $newvirtualmachine | %{$_.split(',')[15]}
	  $root = $newvirtualmachine | %{$_.split(',')[16]}
	  $var = $newvirtualmachine | %{$_.split(',')[17]}
	  $varlog = $newvirtualmachine | %{$_.split(',')[18]}
	  $varlogaudit = $newvirtualmachine | %{$_.split(',')[19]}
	  $home1 = $newvirtualmachine | %{$_.split(',')[20]}
	  $opt = $newvirtualmachine | %{$_.split(',')[21]}
	  $data = $newvirtualmachine | %{$_.split(',')[22]}
	  $usr = $newvirtualmachine | %{$_.split(',')[23]}
	  $tmp = $newvirtualmachine | %{$_.split(',')[24]}
	  $filename = "E:\steel_sa\trunk\rhel5\noarch\sysutil\scripts\PowerCLI\partitioning.ps1"
	  $swapvalue = "<swap>"
	  $rootvalue = "<root>"
	  $varvalue = "<var>"
	  $varlogvalue = "<varlog>"
	  $varlogauditvalue = "<varlogaudit>"
	  $home1value = "<home>"
	  $optvalue = "<opt>"
	  $datavalue = "<data>"
	  $usrvalue = "<usr>"
	  $tmpvalue = "<tmp>"
	  $content = Get-Content $filename
	  $content = $content -creplace $swapvalue,$swap
	  $content = $content -creplace $rootvalue,$root
	  $content = $content -creplace $varvalue,$var
	  $content = $content -creplace $varlogvalue,$varlog
	  $content = $content -creplace $varlogauditvalue,$varlogaudit
	  $content = $content -creplace $home1value,$home1
	  $content = $content -creplace $optvalue,$opt
	  $content = $content -creplace $datavalue,$data
	  $content = $content -creplace $usrvalue,$usr
	  $content = $content -creplace $tmpvalue,$tmp
	  $filename = "$ipaddress.partitioning"
	  $content | Set-Content E:\steel_sa\trunk\rhel5\noarch\sysutil\scripts\PowerCLI\$filename
	Set-Location e:\steel_sa\trunk\rhel5\noarch\sysutil\scripts\PowerCLI
	  c:\cygwin\bin\chmod.exe 777 $filename
	  c:\cygwin\bin\scp.exe $filename sysutil@nces-sb-vm-02.chs.spawar.navy.mil:/var/www/html/partition.files/
   	  c:\cygwin\bin\rm.exe -f $filename
		  # this is a workaround because the dashes, $projectname-2, NECC-1 seem to be interpreted as additonal parameters and i can't escape them no matter what i do.  the answer. better names. going to see if i can change them.
   		 #$esx = Get-VmHost $vmhostserver
  			 #$ds = $esx | Get-Datastore $projectname-2
# the only safey this "delete vm from disk" will be if it's running it will fail to delete   	 

Remove-VM $projectname-$hostname -DeleteFromDisk -Confirm:$false
#$job = Start-Job {Remove-VM $projectname-$hostname -DeleteFromDisk -Confirm:$false}
#Wait-Job $job
#Receive-Job $job
   	   # the below version of New-VM has -ResourcePool included.
	   # New-VM -Name $projectname-$hostname -VMHost $vmhostserver -Location $folderforvm -ResourcePool $resourcepoolforvm -DiskMB $drivesize -MemoryMB $memoryrequired -Datastore $datastorename -Description $notesforvm -GuestId $guestostype -NetworkName $networkname -NumCpu $numbercpu -DiskStorageFormat $diskstorageformat
	   New-VM -Name $projectname-$hostname -VMHost $vmhostserver -Location $folderforvm -DiskMB $drivesize -MemoryMB $memoryrequired -Datastore $datastorename -Notes $notesforvm -GuestId $guestostype -NetworkName $networkname -NumCpu $numbercpu -DiskStorageFormat $diskstorageformat
	  

   	      #Get-VM $projectname-$hostname | Get-NetworkAdapter | Set-NetworkAdapter -Confirm:$false -MacAddress $macaddress

   		 $cd = New-CDDrive -VM $projectname-$hostname -IsoPath "[ISOfiles] $projectname/$hostname.iso"
		 	 Set-CDDrive -Confirm:$false -CD $cd -StartConnected $true
			 Start-VM -VM $projectname-$hostname
   		 # the get-vmguest is just there to give the vm a second to start install before pulling cd
   		 Get-VMGuest -VM $projectname-$hostname
   		 Get-VMGuest -VM $projectname-$hostname
   		 Get-VMGuest -VM $projectname-$hostname
   		 Get-VMGuest -VM $projectname-$hostname
   		 Get-VMGuest -VM $projectname-$hostname
   		 Get-VMGuest -VM $projectname-$hostname
			 Set-CDDrive -Confirm:$false -CD $cd -NoMedia
   	 }