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
<!--[if gt IE 8]> <html class="no-js" lang="en"> <![endif]-->
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">

	<title></title>
	<meta name="description" content="">
	<meta name="author" content="">

	<meta name="viewport" content="width=device-width,initial-scale=1">
<!-- <link rel="stylesheet" type="text/css" href="andreas08.css" title="andreas08" media="screen,projection" /> -->
	<link rel="stylesheet" href="css/style.css"> 

	<script src="js/libs/modernizr-2.0.6.min.js"></script>
</head>
<body>

<div id="contact-form" class="clearfix">  
    <h1>SIM: Server Buildout Form</h1>  
  <h2>Submit Server Requirements to Start Server Buildout</h2>

        <span id="loading"></span>  
        <p id="req-field-desc"><span class="required">*</span> indicates a required field</p>  

<p id="success" class="<?php echo ($sr && $cf['form_ok']) ? 'visible' : ''; ?>">Thanks! We will start building your servers now!  You will receive an email with login information.</p>  

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
<input type="submit" value="Build" id="submit-button" />
<p>
<input type="submit" value="Save" id="submit-button" />
<!-- upload file -->
It is recommended to upload a file for larger numbers of build outs:<br>
<input type="file" name="datafile" />
        <label for="hostname">Hostname: <span class="required">*</span></label>  
        <input type="text" id="hostname" name="hostname" value="" placeholder="host" required="required" autofocus="autofocus" />  
  
        <label for="domain">Domain Name: </label> 
        <select id="domain" name="domain">       
            <option value="chs.spawar.navy.mil">chs.spawar.navy.mil</option>
            <option value="spawar-chas.navy.smil.mil">spawar-chas.navy.smil.mil</option>
            <option value="example.com">example.com</option>
        </select>

        <label for="nic">NIC: </label> 
        <select id="nic" name="nic">       
            <option value="eth0">eth0</option>
            <option value="eth1">eth1</option>
            <option value="eth2">eth2</option>
            <option value="em1">em1</option>
            <option value="em2">em2</option>
            <option value="em3">em3</option>
        </select>

        <label for="mac">Mac: <span class="required">*</span></label>  
        <input type="text" id="mac" name="mac" value="" placeholder="00:50:56:00:00:00" required="required" />  
  
        <label for="ip">IP: <span class="required">*</span></label>  
        <input type="text" id="ip" name="ip" value="" placeholder="192.168.10.25" required="required" />  
  
        <label for="mask">MASK: <span class="required">*</span></label>  
        <input type="text" id="mask" name="mask" value="255.255.255.0" placeholder="" required="required" />  
  
<!--        <label for="gateway">GATEWAY: <span class="required">*</span></label>  
        <input type="text" id="gateway" name="gateway" value="150.125.72.1" placeholder="" required="required" />  
-->
        <label for="gateway">GATEWAY: </label> 
        <select id="gateway" name="gateway">       
            <option value="150.125.72.1">150.125.72.1</option>
            <option value="150.125.75.1">150.125.75.1</option>
            <option value="198.253.24.1">198.253.24.1</option>
        </select>

  
        <label for="dns1">DNS1: <span class="required">*</span></label>  
        <input type="text" id="dns1" name="dns1" value="150.125.132.20" placeholder="" required="required" />  
  
        <label for="dns2">DNS2: <span class="required">*</span></label>  
        <input type="text" id="dns2" name="dns2" value="150.125.132.24" placeholder="" required="required" />  
  
        <label for="disc">Disc Size (In Kilobytes): <span class="required">*</span></label>  
        <input type="text" id="disc" name="disc" value="12000000" placeholder="" required="required" />  
  
        <label for="ram">RAM (In Megabytes): <span class="required">*</span></label>  
        <input type="text" id="ram" name="ram" value="384" placeholder="" required="required" />  
  
        <label for="esxihost">VMware ESXi Host: </label> 
        <select id="esxihost" name="esxihost">       
            <option value="ges107lwn1.chs.spawar.navy.mil">ges107lwn1.chs.spawar.navy.mil</option>
            <option value="ges507lwn1.chs.spawar.navy.mil">ges507lwn1.chs.spawar.navy.mil</option>
            <option value="ges607lwn1.chs.spawar.navy.mil">ges607lwn1.chs.spawar.navy.mil</option>
            <option value="c2ebl011.c2e.lab">c2ebl011.c2e.lab</option>
            <option value="c2ebl012.c2e.lab">c2ebl012.c2e.lab</option>
            <option value="c2ebl013.c2e.lab">c2ebl013.c2e.lab</option>
            <option value="c2ebl014.c2e.lab">c2ebl014.c2e.lab</option>
        </select>

        <label for="guestos">VMware Guest OS: </label> 
        <select id="guestos" name="guestos">       
            <option value="rhel5_64Guest">rhel5_64Guest</option>
            <option value="rhel6_64Guest">rhel6_64Guest</option>
            <option value="sles11_64Guest">sles11_64Guest</option>
            <option value="windows7Server64Guest">windows7Server64Guest</option>
        </select>

        <label for="vmnetwork">VMware VM Network: </label> 
        <select id="vmnetwork" name="vmnetwork">       
            <option value="trusted72">trusted72</option>
            <option value="trusted75">trusted75</option>
            <option value="Trusted VM Network">Trusted VM Network</option>
            <option value="VM Network">VM Network</option>
        </select>

        <label for="nicpwr">NIC PWR: <span class="required">*</span></label>  
        <input type="text" id="nicpwr" name="nicpwr" value="0" placeholder="" required="required" />  
  
        <label for="cpus">Number of CPU's: <span class="required">*</span></label>  
        <input type="text" id="cpus" name="cpus" value="1" placeholder="" required="required" />  
  
        <label for="vcenter">VMware VCenter: </label> 
        <select id="vcenter" name="vcenter">       
            <option value="vcenterges01.chs.spawar.navy.mil">vcenterges01</option>
            <option value="c2e-vcenter">c2e-vcenter</option>
        </select>

<!--        <label for="vcenter">VMware VCenter: <span class="required">*</span></label>  
        <input type="text" id="vcenter" name="vcenter" value="c2e-vcenter" placeholder="" required="required" />  
-->
  
        <label for="vcenteruser">VMware VCenter User: <span class="required">*</span></label>  
        <input type="text" id="vcenteruser" name="vcenteruser" value="ges_admin" placeholder="" required="required" />  
  
        <label for="vcenteruserpasswd">VMware VCenter User Passwd: <span class="required">*</span></label>  
        <input type="password" id="vcenteruserpasswd" name="vcenteruserpasswd" value="P@$$w0rdP@$$w0rd" placeholder="" required="required" />  
  
        <label for="satuser">Satellite User: <span class="required">*</span></label>  
        <input type="text" id="satuser" name="satuser" value="admin-ges" placeholder="" required="required" />  
  
        <label for="satuserpasswd">Satellite User Passwd: <span class="required">*</span></label>  
        <input type="password" id="satuserpasswd" name="satuserpasswd" value="'munge'" placeholder="" required="required" />  
  
        <label for="satorgid">Satellite Organization ID: <span class="required">*</span></label>  
        <input type="text" id="satorgid" name="satorgid" value="2" placeholder="" required="required" />  
  
        <label for="esxiuser">ESXi Host User: <span class="required">*</span></label>  
        <input type="text" id="esxiuser" name="esxiuser" value="root" placeholder="" required="required" />  
  
        <label for="esxiuserpasswd">ESXi Host User Passwd: <span class="required">*</span></label>  
        <input type="password" id="esxiuserpasswd" name="esxiuserpasswd" value="P@$$w0rd" placeholder="" required="required" />  
<!--        <input type="password" id="esxiuserpasswd" name="esxiuserpasswd" value="N3ccJt0cc!N3ccJt0cc!" placeholder="" required="required" />  
-->
        <label for="project">Project Name (keep it simple, ges): <span class="required">*</span></label>  
        <input type="text" id="project" name="project" value="ges" placeholder="" required="required" />  
  
        <label for="vmnotes">POC for Service (Aaron_Prayther_x2178): <span class="required">*</span></label>  
        <input type="text" id="vmnotes" name="vmnotes" value="" placeholder="Service_Name,_POC_and_contact_info" required="required" />  
  
        <label for="datastore">Datastore: </label> 
        <select id="datastore" name="datastore">       
            <option value="gesrhel5">gesrhel5</option>
            <option value="gesrhel6">gesrhel6</option>
            <option value="gessol">gessol</option>
            <option value="ges2003">ges2003</option>
            <option value="ges2008">ges2008</option>
        </select>

        <label for="architecture">Architecture: </label> 
        <select id="architecture" name="architecture">       
            <option value="x86_64">x86_64</option>
            <option value="i386">i386</option>
        </select>

        <label for="rhelversion">RHEL Version: </label> 
        <select id="rhelversion" name="rhelversion">       
            <option value="rhel5">rhel5</option>
            <option value="rhel6">rhel6</option>
        </select>

        <label for="isodatastore">ISO Datastore: </label> 
        <select id="isodatastore" name="isodatastore">       
            <option value="ISOfiles">ISOfiles</option>
            <option value="datastore1">datastore1</option>
        </select>

        <label for="folder">VMware Folder: </label>  
        <input type="text" id="folder" name="folder" value="" placeholder="Folder name in VM & Templates view" />  
  
        <label for="resourcepool">VMware Resource Pool: </label>  
        <input type="text" id="resourcepool" name="resourcepool" value="" />  
  
        <label for="datacenter">VMware Virtual DataCenter: </label> 
        <select id="datacenter" name="datacenter">       
            <option value="GES">GES</option>
            <option value="C2E">C2E</option>
        </select>

        <label for="discformat">VMware VM Disc Format: </label> 
        <select id="discformat" name="discformat">       
            <option value="thin">thin</option>
            <option value="thick">thick</option>
        </select>

        <label for="env">Release Environment: </label> 
        <select id="env" name="env">       
            <option value="dev">Development</option>
            <option value="tst">Test & Integration</option>
            <option value="refimp">Reference Implementation</option>
            <option value="preprod"></option>
        </select>

        <label for="role">Role: <span class="required">*</span></label>
        <input type="text" id="role" name="role" value="role" placeholder="" required="required" />

        <label for="tmp">TMP Disc Size: <span class="required">*</span></label>  
        <input type="text" id="tmp" name="tmp" value="1024" placeholder="" required="required" />  
  
        <label for="usr">USR Disc Size: <span class="required">*</span></label>  
        <input type="text" id="usr" name="usr" value="2048" placeholder="" required="required" />  
  
        <label for="data">DATA Disc Size: <span class="required">*</span></label>  
        <input type="text" id="data" name="data" value="33" placeholder="" required="required" />  
  
        <label for="opt">OPT Disc Size: <span class="required">*</span></label>  
        <input type="text" id="opt" name="opt" value="1024" placeholder="" required="required" />  
  
        <label for="home">HOME Disc Size: <span class="required">*</span></label>  
        <input type="text" id="home" name="home" value="512" placeholder="" required="required" />  
  
        <label for="var">VAR Disc Size: <span class="required">*</span></label>  
        <input type="text" id="var" name="var" value="2048" placeholder="" required="required" />  
  
        <label for="varlog">VAR/LOG Disc Size: <span class="required">*</span></label>  
        <input type="text" id="varlog" name="varlog" value="1024" placeholder="" required="required" />  
  
        <label for="varlogaudit">VAR/LOG/AUDIT Disc Size: <span class="required">*</span></label>  
        <input type="text" id="varlogaudit" name="varlogaudit" value="200" placeholder="" required="required" />  
  
        <label for="root">ROOT Disc Size: <span class="required">*</span></label>  
        <input type="text" id="root" name="root" value="1024" placeholder="" required="required" />  
  
        <label for="swap">SWAP Disc Size: <span class="required">*</span></label>  
        <input type="text" id="swap" name="swap" value="1024" placeholder="" required="required" />  
  
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
<input type="submit" value="Build" id="submit-button" />
<p>
<input type="submit" value="Save" id="submit-button" />
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
