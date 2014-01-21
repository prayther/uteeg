<?php  
if( isset($_POST) ){  
  
    //form validation vars  
    $formok = true;  
    $errors = array();  
  
    //submission data  
    $ipaddress = $_SERVER['REMOTE_ADDR'];  
    $date = date('d/m/Y');  
    $time = date('H:i:s');  
  
    //form data  
    $name = $_POST['name'];  
    $email = $_POST['email'];  
    $telephone = $_POST['telephone'];  
    $hostname = $_POST['hostname'];
    $mac = $_POST['mac'];
    $ip = $_POST['ip'];
    $resourcepool = $_POST['resourcepool'];
    $folder = $_POST['folder'];
    $esxihost = $_POST['esxihost'];
    $disc = $_POST['disc'];
    $ram = $_POST['ram'];
    $datastore = $_POST['datastore'];
    $vmnotes = $_POST['vmnotes'];
    $guestos = $_POST['guestos'];
    $vmnetwork = $_POST['vmnetwork'];
    $project = $_POST['project'];
    $cpus = $_POST['cpus'];
    $discformat = $_POST['discformat'];
    $swap = $_POST['swap'];
    $var = $_POST['var'];
    $varlog = $_POST['varlog'];
    $varlogaudit = $_POST['varlogaudit'];
    $home = $_POST['home'];
    $opt = $_POST['opt'];
    $data = $_POST['data'];
    $usr = $_POST['usr'];
    $tmp = $_POST['tmp'];
    $role = $_POST['role'];
    $mask = $_POST['mask'];
    $gateway = $_POST['gateway'];
    $dns1 = $_POST['dns1'];
    $dns2 = $_POST['dns2'];
    $datacenter = $_POST['datacenter'];
    $nicpwr = $_POST['nicpwr'];
    $env = $_POST['env'];
    $isodatastore = $_POST['isodatastore'];
    $vcenteruser = $_POST['vcenteruser'];
    $vcenteruserpasswd = $_POST['vcenteruserpasswd'];
    $vcenter = $_POST['vcenter'];
    $rhelversion = $_POST['rhelversion'];
    $architecture = $_POST['architecture'];
    $domain = $_POST['domain'];
    $nic = $_POST['nic'];
    $satuser = $_POST['satuser'];
    $satuserpasswd = $_POST['satuserpasswd'];
    $esxiuser = $_POST['esxiuser'];
    $esxiuserpasswd = $_POST['esxiuserpasswd'];
    $satorgid = $_POST['satorgid'];
//    $enquiry = $_POST['enquiry'];  
//    $message = $_POST['message'];  

    //validate form data  
  
    //validate hostname is not empty  
    if(empty($hostname)){  
        $formok = false;  
        $errors[] = "You have not entered a hostname";  
    }  
  
    //validate mac is not empty  
    if(empty($mac)){  
        $formok = false;  
        $errors[] = "You have not entered a mac";  
    }  
  
    //validate ip is not empty  
    if(empty($ip)){  
        $formok = false;  
        $errors[] = "You have not entered an ip";  
    }  
  
    //validate vmnotes is not empty  
    if(empty($vmnotes)){  
        $formok = false;  
        $errors[] = "You have not entered any vmnotes";  
    }  
  
    //validate name is not empty  
    if(empty($name)){  
        $formok = false;  
        $errors[] = "You have not entered a name";  
    }  
  
    //validate email address is not empty  
    if(empty($email)){  
        $formok = false;  
        $errors[] = "You have not entered an email address";  
    }  
  
    //validate message is not empty  
//    if(empty($message)){  
//        $formok = false;  
//        $errors[] = "You have not entered a message";  
//    }  
    //validate message is greater than 20 characters  
//    elseif(strlen($message) < 20){  
//        $formok = false;  
//        $errors[] = "Your message must be greater than 20 characters";  
//    }  
  
    //send email if all is ok  
    if($formok){  
        $headers = "From: SIM@rhn.spawar.navy.mil" . "\r\n";  
        $headers .= 'Content-type: text/html; charset=iso-8859-1' . "\r\n";  
  
        $emailbody = "<p>You have received a new message from the enquiries form on your website.</p> 
                      <p><strong>Name: </strong> {$name} </p> 
                      <p><strong>Email Address: </strong> {$email} </p> 
                      <p><strong>Telephone: </strong> {$telephone} </p> 
                      <p><strong>Enquiry: </strong> {$enquiry} </p> 
                      <p><strong>Message: </strong> {$message} </p> 
                      <p>This message was sent from the IP Address: {$ipaddress} on {$date} at {$time}</p>";  
  
        mail("aprayther@lce.com","SIM $name submitted",$emailbody,$headers);  
        mail($email,"Data You Submitted to SIM to be Provisioned",$emailbody,$headers);  
  
    }  
  
    //what we need to return back to our form  
    $returndata = array(  
        'posted_form_data' => array(  
            'name' => $name,  
            'email' => $email,  
            'telephone' => $telephone,  
            'enquiry' => $enquiry,  
            'message' => $message  
        ),  
        'form_ok' => $formok,  
        'errors' => $errors  
    );  

    $returnstring = "$hostname,$mac,$ip,$resourcepool,$folder,$esxihost,$disc,$ram,$datastore,$vmnotes,$guestos,$vmnetwork,$project,$cpus,$discformat,$swap,$var,$varlog,$varlogaudit,$home,$opt,$data,$usr,$tmp,$role,$mask,$gateway,$dns1,$dns2,$datacenter,$nicpwr,$env,$isodatastore,$vcenteruser,$vcenteruserpasswd,$vcenter,$rhelversion,$architecture,$domain,$nic,$satuser,$satuserpasswd,$esxiuser,$esxiuserpasswd,$satorgid";

###################### Set up the following variables ######################
# #
$filename = "output/output.txt"; #CHMOD to 666
$forward = 0; # redirect? 1 : yes || 0 : no
$location = "thankyou.htm"; #set page to redirect to, if 1 is above
# #
##################### No need to edit below this line ######################

## set time up ##

$date = date ("l, F jS, Y");
$time = date ("h:i A");

## mail message ##

$msg = "Below is the result of your feedback form. It was submitted on $date at $time.\n\n";

foreach ($_POST as $key => $value)
{
$msg .= ucfirst ($key) ." : ". $value . "\n";
}

$msg .= "-----------\n\n";

$fp = fopen ($filename, "a"); # w = write to the file only, create file if it does not exist, discard existing contents
if ($fp) {
fwrite ($fp, $returnstring);
fclose ($fp);
}
else {
$forward = 2;
}

if ($forward == 1) {
header ("Location:$location");
}
else if ($forward == 0) {
echo ("Thank you for submitting our form. We will get back to you as soon as possible.");
}
else {
"Error processing form. Please contact the webmaster";
}
########################## finish writing file ###############################
  
    //if this is not an ajax request  
    if(empty($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) !== 'xmlhttprequest'){  
        //set session variables  
        session_start();  
        $_SESSION['cf_returndata'] = $returndata;  
  
        //redirect back to form  
        header('location: ' . $_SERVER['HTTP_REFERER']);  
    }  
} 