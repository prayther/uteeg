# Operating Systems are automatically added as the kickstart repos are synchronised.
# Associate the operating systems hosted on this server with the specified organisation and location.
ORG='redhat'
LOC='laptop'
for i in $(hammer --csv medium list | grep $(hostname) | cut -d, -f1)
do
   hammer organization add-medium --name ${ORG} --medium-id ${i}
   hammer location add-medium --name ${LOC} --medium-id ${i}
done

