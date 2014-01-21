clear
Connect-VIServer -server C2E-VCenter -user aprayther -password qweQWE123!@#123

foreach ( $mac in get-content Z:\fedora\sa\trunk\docs\Technical\powergui\get_macs.txt )
   	 {

Get-NetworkAdapter -VM nces-$mac
}


