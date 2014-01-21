<?php 
require_once("IXR_Library.php");
 
$client->debug = true; //Set it to false in Production Environment
 
$title="SERVICENAME ENVIRONMENTCAPS"; // $title variable will insert your blog title 
$body='
<table border="0">
  <tr>
<!--
##START##-->


</td>
</tr>
</table>
'; // $body will insert your blog content (article content)
 
#$category="category1, category2"; // Comma seperated pre existing categories. Ensure that these categories exists in your blog.
#$category="uncategorized"; // Comma seperated pre existing categories. Ensure that these categories exists in your blog.
$category="SERVICENAME_ENVIRONMENTCAPS"; // Comma seperated pre existing categories. Ensure that these categories exists in your blog.
$keywords="SERVICENAME, ENVIRONMENTCAPS";
 
$customfields=array('key'=>'Author-bio', 'value'=>'Autor Bio Here'); // Insert your custom values like this in Key, Value format
 
 
    #$title = htmlentities($title,ENT_NOQUOTES,$encoding);
    #$keywords = htmlentities($keywords,ENT_NOQUOTES,$encoding);
 
    $content = array(
        'title'=>$title,
        'description'=>$body,
        'mt_allow_comments'=>0,  // 1 to allow comments
        'mt_allow_pings'=>0,  // 1 to allow trackbacks
        'post_type'=>'post',
        #'post_type'=>'page',
        'mt_keywords'=>$keywords,
        'categories'=>array($category),
		'custom_fields' =>  array($customfields)
 
 
    );
 
// Create the client object
#$client = new IXR_Client('Your Blog Path/xmlrpc.php');
$client = new IXR_Client('http://beef/xmlrpc.php');
 
 #$username = "USERNAME"; 
 #$password = "PASSWORD"; 
 $username = "xmlrpc"; 
 $password = "munge"; 
 $params = array(0,$username,$password,$content,true); // Last parameter is 'true' which means post immideately, to save as draft set it as 'false'
 
// Run a query for PHP
if (!$client->query('metaWeblog.newPost', $params)) {
    die('Something went wrong - '.$client->getErrorCode().' : '.$client->getErrorMessage());
}
else
    echo "Article Posted Successfully";
 
?>