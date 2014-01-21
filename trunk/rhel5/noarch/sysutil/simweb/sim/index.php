<?php session_start() ?>
<?php  
//init variables  
$cf = array();  
$sr = false;  
  
if(isset($_SESSION['cf_returndata'])){  
    $cf = $_SESSION['cf_returndata'];  
    $sr = true;  
}  
?>
<!doctype html>
<!--[if lt IE 7]> <html class="no-js ie6 oldie" lang="en"> <![endif]-->
<!--[if IE 7]>    <html class="no-js ie7 oldie" lang="en"> <![endif]-->
<!--[if IE 8]>    <html class="no-js ie8 oldie" lang="en"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js" lang="en"> <!--<![endif]-->
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">

	<title></title>
	<meta name="description" content="">
	<meta name="author" content="aprayther" >

	<meta name="viewport" content="width=device-width,initial-scale=1">

	<link rel="stylesheet" href="css/style.css">

	<script src="js/libs/modernizr-2.0.6.min.js"></script>
</head>
<body>

<div id="contact-form" class="clearfix">  
    <h1>SIM: Server Buildout Form</h1>  
  <h2>Submit Server Requirements to Start Server Buildout</h2>

        <span id="loading"></span>  
        <input type="submit" value="OK!" id="submit-button" />  
        <p id="req-field-desc"><span class="required">*</span> indicates a required field</p>  

<p id="success" class="<?php echo ($sr && $cf['form_ok']) ? 'visible' : ''; ?>">Thanks! We will start building your servers now!</p>  

<ul id="errors" class="<?php echo ($sr && !$cf['form_ok']) ? 'visible' : ''; ?>">  
    <li id="info">There were some problems with your form submission:</li>  
    <?php  
    if(isset($cf['errors']) && count($cf['errors']) > 0) :  
        foreach($cf['errors'] as $error) :  
    ?>  
    <li><?php echo $error ?></li>  
    <?php  
        endforeach;  
    endif;  
    ?>  
</ul> 

<!-- Form fields defined here -->
    <form method="post" action="process.php">  
        <label for="hostname">Hostname: <span class="required">*</span></label>  
        <input type="text" id="hostname" name="hostname" value="" placeholder="host.chs.spawar.navy.mil" required="required" autofocus="autofocus" />  
  
        <label for="domain">Domain Name: </label> 
        <select id="domain" name="domain">       
            <option value="domain">chs.spawar.navy.mil</option>
            <option value="domain">spawar-chas.navy.smil.mil</option>
            <option value="domain">example.com</option>
        </select>

        <label for="nic">NIC: </label> 
        <select id="nic" name="nic">       
            <option value="nic">eth0</option>
            <option value="nic">eth1</option>
            <option value="nic">eth2</option>
            <option value="nic">em1</option>
            <option value="nic">em2</option>
            <option value="nic">em3</option>
        </select>

        <label for="mac">Mac: <span class="required">*</span></label>  
        <input type="text" id="mac" name="mac" value="" placeholder="00:50:56:00:00:00" required="required" />  
  
        <label for="ip">IP: <span class="required">*</span></label>  
        <input type="text" id="ip" name="ip" value="" placeholder="192.168.10.25" required="required" />  
  
        <label for="mask">MASK: <span class="required">*</span></label>  
        <input type="text" id="mask" name="mask" value="255.255.255.0" placeholder="" required="required" />  
  
        <label for="gateway">GATEWAY: <span class="required">*</span></label>  
        <input type="text" id="gateway" name="gateway" value="150.125.72.1" placeholder="" required="required" />  
  
        <label for="dns1">DNS1: <span class="required">*</span></label>  
        <input type="text" id="dns1" name="dns1" value="150.125.132.20" placeholder="" required="required" />  
  
        <label for="dns2">DNS2: <span class="required">*</span></label>  
        <input type="text" id="dns2" name="dns2" value="150.125.132.24" placeholder="" required="required" />  
  
        <label for="disc">Disc Size (In Kilobytes): <span class="required">*</span></label>  
        <input type="text" id="disc" name="disc" value="400000" placeholder="" required="required" />  
  
        <label for="ram">RAM (In Megabytes): <span class="required">*</span></label>  
        <input type="text" id="ram" name="ram" value="384" placeholder="" required="required" />  
  
        <label for="esxihost">VMware ESXi Host: </label> 
        <select id="esxihost" name="esxihost">       
            <option value="esxihost">c2ebl011.c2e.lab</option>
            <option value="esxihost">c2ebl012.c2e.lab</option>
            <option value="esxihost">c2ebl013.c2e.lab</option>
            <option value="esxihost">c2ebl014.c2e.lab</option>
        </select>

        <label for="guestos">VMware Guest OS: </label> 
        <select id="guestos" name="guestos">       
            <option value="guestos">rhel5_64Guest</option>
            <option value="guestos">rhel6_64Guest</option>
            <option value="guestos">sles11_64Guest</option>
            <option value="guestos">windows7Server64Guest</option>
        </select>

        <label for="vmnetwork">VMware VM Network: </label> 
        <select id="vmnetwork" name="vmnetwork">       
            <option value="vmnetwork">Trusted VM Network</option>
            <option value="vmnetwork">VM Network</option>
        </select>

        <label for="nicpwr">NIC PWR: <span class="required">*</span></label>  
        <input type="text" id="nicpwr" name="nicpwr" value="0" placeholder="" required="required" />  
  
        <label for="cpus">Number of CPU's: <span class="required">*</span></label>  
        <input type="text" id="cpus" name="cpus" value="1" placeholder="" required="required" />  
  
        <label for="vcenter">VMware VCenter: <span class="required">*</span></label>  
        <input type="text" id="vcenter" name="vcenter" value="c2e-vcenter" placeholder="" required="required" />  
  
        <label for="vcenteruser">VMware VCenter User: <span class="required">*</span></label>  
        <input type="text" id="vcenteruser" name="vcenteruser" value="aprayther" placeholder="" required="required" />  
  
        <label for="vcenteruserpasswd">VMware VCenter User Passwd: <span class="required">*</span></label>  
        <input type="password" id="vcenteruserpasswd" name="vcenteruserpasswd" value="qweQWE123!@#123" placeholder="" required="required" />  
  
        <label for="satuser">Satellite User: <span class="required">*</span></label>  
        <input type="text" id="satuser" name="satuser" value="admin-ges" placeholder="" required="required" />  
  
        <label for="satuserpasswd">Satellite User Passwd: <span class="required">*</span></label>  
        <input type="password" id="satuserpasswd" name="satuserpasswd" value="P@$$w0rd" placeholder="" required="required" />  
  
        <label for="satorgid">Satellite Organization ID: <span class="required">*</span></label>  
        <input type="text" id="satorgid" name="satorgid" value="2" placeholder="" required="required" />  
  
        <label for="esxiuser">ESXi Host User: <span class="required">*</span></label>  
        <input type="text" id="esxiuser" name="esxiuser" value="root" placeholder="" required="required" />  
  
        <label for="esxiuserpasswd">ESXi Host User Passwd: <span class="required">*</span></label>  
        <input type="password" id="esxiuserpasswd" name="esxiuserpasswd" value="'N3ccJt0cc!N3ccJt0cc!'" placeholder="" required="required" />  
  
        <label for="project">Project Name (keep it simple, ges): <span class="required">*</span></label>  
        <input type="text" id="project" name="project" value="ges" placeholder="" required="required" />  
  
        <label for="vmnotes">VMNotes Field (for now, all spaces will be removed from this. Use _ -, etc): <span class="required">*</span></label>  
        <input type="text" id="vmnotes" name="vmnotes" value="" placeholder="Service_Name,_POC_and_contact_info" required="required" />  
  
        <label for="datastore">Datastore: </label> 
        <select id="datastore" name="datastore">       
            <option value="datastore">ges1</option>
            <option value="datastore">ges2</option>
            <option value="datastore">ges3</option>
            <option value="datastore">ges4</option>
            <option value="datastore">datastore1</option>
        </select>

        <label for="architecture">Architecture: </label> 
        <select id="architecture" name="architecture">       
            <option value="architecture">x86_64</option>
            <option value="architecture">i386</option>
        </select>

        <label for="rhelversion">RHEL Version: </label> 
        <select id="rhelversion" name="rhelversion">       
            <option value="rhelversion">rhel5</option>
            <option value="rhelversion">rhel6</option>
        </select>

        <label for="isodatastore">ISO Datastore: </label> 
        <select id="isodatastore" name="isodatastore">       
            <option value="isodatastore">[ISOfiles]</option>
            <option value="isodatastore">datastore1</option>
        </select>

        <label for="folder">VMware Folder: </label>  
        <input type="text" id="folder" name="folder" value="" placeholder="Folder name in VM & Templates view" />  
  
        <label for="resourcepool">VMware Resource Pool: </label>  
        <input type="text" id="resourcepool" name="resourcepool" value="" />  
  
        <label for="datacenter">VMware Virtual DataCenter: </label> 
        <select id="datacenter" name="datacenter">       
            <option value="datacenter">GES</option>
            <option value="datacenter">C2E</option>
        </select>

        <label for="discformat">VMware VM Disc Format: </label> 
        <select id="discformat" name="discformat">       
            <option value="discformat">thin</option>
            <option value="discformat">thick</option>
        </select>

        <label for="env">Environment: </label> 
        <select id="env" name="env">       
            <option value="env">tst</option>
            <option value="env">dev</option>
            <option value="env">refimp</option>
            <option value="env">preprod</option>
            <option value="env">prod</option>
        </select>

        <label for="role">Role: </label> 
        <select id="role" name="role">       
            <option value="role">role</option>
            <option value="role">db01</option>
            <option value="role">db02</option>
            <option value="role">em1</option>
            <option value="role">em2</option>
        </select>

        <label for="tmp">TMP Disc Size: <span class="required">*</span></label>  
        <input type="text" id="tmp" name="tmp" value="33" placeholder="" required="required" />  
  
        <label for="usr">USR Disc Size: <span class="required">*</span></label>  
        <input type="text" id="usr" name="usr" value="1000" placeholder="" required="required" />  
  
        <label for="data">DATA Disc Size: <span class="required">*</span></label>  
        <input type="text" id="data" name="data" value="33" placeholder="" required="required" />  
  
        <label for="opt">OPT Disc Size: <span class="required">*</span></label>  
        <input type="text" id="opt" name="opt" value="33" placeholder="" required="required" />  
  
        <label for="home">HOME Disc Size: <span class="required">*</span></label>  
        <input type="text" id="home" name="home" value="33" placeholder="" required="required" />  
  
        <label for="var">VAR Disc Size: <span class="required">*</span></label>  
        <input type="text" id="var" name="var" value="1500" placeholder="" required="required" />  
  
        <label for="varlog">VAR/LOG Disc Size: <span class="required">*</span></label>  
        <input type="text" id="varlog" name="varlog" value="33" placeholder="" required="required" />  
  
        <label for="varlogaudit">VAR/LOG/AUDIT Disc Size: <span class="required">*</span></label>  
        <input type="text" id="varlogaudit" name="varlogaudit" value="33" placeholder="" required="required" />  
  
        <label for="root">ROOT Disc Size: <span class="required">*</span></label>  
        <input type="text" id="root" name="root" value="500" placeholder="" required="required" />  
  
        <label for="swap">SWAP Disc Size: <span class="required">*</span></label>  
        <input type="text" id="swap" name="swap" value="33" placeholder="" required="required" />  
  
        <label for="name">Name: <span class="required">*</span></label>  
        <input type="name" id="name" name="name" value="" placeholder="john doe" required="required" />  
  
        <label for="email">Email Address: <span class="required">*</span></label>  
        <input type="email" id="email" name="email" value="" placeholder="johndoe@example.com" required="required" />  
  
        <label for="telephone">Telephone: </label>  
        <input type="tel" id="telephone" name="telephone" value="" />  
  
<!--        <label for="enquiry">Enquiry: </label>  
        <select id="enquiry" name="enquiry">  
            <option value="general">General</option>  
            <option value="sales">Sales</option>  
            <option value="support">Support</option>  
        </select>  
  
        <label for="message">Message: <span class="required">*</span></label>  
        <textarea id="message" name="message" placeholder="Your message must be greater than 20 charcters" required="required" data-minlength="20"></textarea>  

        <span id="loading"></span>  
        <input type="submit" value="OK!" id="submit-button" />  
        <p id="req-field-desc"><span class="required">*</span> indicates a required field</p>  
-->
        <input type="submit" value="OK!" id="submit-button" />  
    </form>  
</div>  

<script src="//ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
<script>window.jQuery || document.write('<script src="js/libs/jquery-1.7.1.min.js"><\/script>')</script>

<!-- scripts concatenated and minified via ant build script-->
<script src="js/plugins.js"></script>
<script src="js/script.js"></script>
<!-- end scripts-->

<!-- <script>
	var _gaq=[['_setAccount','UA-XXXXX-X'],['_trackPageview']]; // Change UA-XXXXX-X to be your site's ID
	(function(d,t){var g=d.createElement(t),s=d.getElementsByTagName(t)[0];g.async=1;
	g.src=('https:'==location.protocol?'//ssl':'//www')+'.google-analytics.com/ga.js';
	s.parentNode.insertBefore(g,s)}(document,'script'));

<!--[if lt IE 7 ]>
	<script src="//ajax.googleapis.com/ajax/libs/chrome-frame/1.0.2/CFInstall.min.js"></script>
	<script>window.attachEvent("onload",function(){CFInstall.check({mode:"overlay"})})</script>
<![endif]-->

</body>
</html>