<?php
 function AA_shortcode( $atts )
 { extract(shortcode_atts(array('keywords' => '', ), $atts));

$siteurl =get_option('home');;

add_option( 'AACJ_on', '');
add_option( 'AAAZ_locale', '');
add_option( 'AACJ_websiteid', '' );
add_option( 'AACJ_CJ_DevKey', '' );
add_option( 'AACJ_cj_amount', '' );
add_option( 'AAAZ_on', '' );
add_option( 'AAebay_on', '' );
add_option( 'AAAZ_public_key', '' );
add_option( 'AAAZ_private_key', '' );
add_option( 'AAAZ_associateus', '' );
add_option( 'AAAZ_associatede', '' );
add_option( 'AAAZ_associatefr', '' );
add_option( 'AAAZ_associatejp', '' );
add_option( 'AAAZ_associateuk', '' );
add_option( 'AAAZ_associateca', '' );
add_option( 'AAebay_campaign_id', '' );
$websiteIdx = get_option('AACJ_websiteid', '' );
$cj = get_option('AACJ_on');
if ($cj == 1){
  if ($amount == ''){
  $amount1 = 3;
}
else {
  $amount1 = $amount;
}
$cjword = urlencode($keywords);
$devkey = get_option('AACJ_CJ_DevKey');
$amount = get_option('AACJ_cj_amount');
$url = "https://product-search.api.cj.com/v2/product-search?&website-id=$websiteIdx&advertiser-ids=joined&keywords=$cjword&records-per-page=$amount1";
 $cjconn = curl_init($url);
 curl_setopt($cjconn, CURLOPT_POST, FAlSE);
 curl_setopt($cjconn, CURLOPT_HTTPHEADER, array('Authorization: '.$devkey));
 curl_setopt($cjconn, CURLOPT_SSL_VERIFYPEER, FALSE);
 curl_setopt($cjconn, CURLOPT_RETURNTRANSFER, TRUE);
 $returns = curl_exec($cjconn);
 curl_close($cjconn);
 $results = simplexml_load_string($returns);
 foreach ($results->products->product as $i) {
   $click_url = $i->xpath('buy-url');
   $click_url = $click_url[0];
   $image_url = $i->xpath('image-url');
   $image_url = (string)$image_url[0];
   $name = $i->xpath('name');
   $name =(string)$name[0];
   $price = $i->xpath('price');
   $price = $price[0];$currency = $i->xpath('currency');
   $currency = $currency[0];
   $description = $i->xpath('description');
   $description = $description[0];
 //$nama = seo_str($name);
 /****************************************************************************
 The FOLLOWING PARAGRAPH IS WHERE THE CJ ADS WILL APPEAR IN THE POST. YOU CAN
 CHANGE THE FORMATTING LEAVING THE $ STRINGS INTACT. IN A FUTURE RELEASE YOU 
 WILL BE GIVEN THE OPTION TO CHANGE THE APPEARANCE ON THE FLY. ANYWAY, ADJUST 
 THIS TO APPEAR THE EXACT WAY THAT YOU LIKE!
 ****************************************************************************/
$l1 .= '<table border="0"><tr><td><h2><font size="3">'.$name.'</font></h2></a><br><font size="2"><b>$ '.number_format((string)$price[0],2).' </font></b><br><img src="'.$image_url.'" title="'.$name.'" border="0"></a><br>'.$description.'<br></td></tr>
<tr><td><a href="'.$click_url.'"><img src="'.$siteurl.'/wp-content/plugins/actionaffiliate/images/more.jpg" /></a>
</td></tr></table> '
;}
}
else
{
  $l1 .='';
}
$az = get_option('AAAZ_on');
if ($az == 1){
include "./wp-content/plugins/actionaffiliate/includes/amazon.php";
 }
else {
  $l1 .= '';
}
$eb = get_option('AAebay_on');
if ($eb == 1) {
  $epn_campaign_id = get_option('AAebay_campaign_id');
  $ebayword = urlencode($keywords);
  $display = $amount;
  $newwindow = "0";
  //The next line is to be further developed in a future release.
  $country1 = "24";
include "./wp-content/plugins/actionaffiliate/includes/nicheresults.php";
}
else {
  $l1 .= '';
}
return $l1;
}
function add_actionaffiliate_panel() {if (function_exists('add_options_page')) {
  add_options_page('Action Affiliate for Wordpress', 'actionaffiliate', 8, 'AA', 'actionaffiliate_admin_panel');}}
  function actionaffiliate_admin_panel() {if ($_POST["aa_updated"]){
    update_option('AACJ_on',$_POST['AACJ_on']);
    update_option('AACJ_websiteid',$_POST['AACJ_websiteid']);
    update_option('AACJ_CJ_DevKey',$_POST['AACJ_CJ_DevKey']);
    update_option('AACJ_cj_amount',$_POST['AACJ_cj_amount']);
    update_option('AACJ_amount',$_POST['AACJ_amount']);
    update_option('AAAZ_on',$_POST['AAAZ_on']);
    update_option('AAAZ_locale',$_POST['AAAZ_locale']);
    update_option('AAAZ_public_key',$_POST['AAAZ_public_key']);
    update_option('AAAZ_private_key',$_POST['AAAZ_private_key']);
    update_option('AAAZ_associateus',$_POST['AAAZ_associateus']);
    update_option('AAAZ_associatede',$_POST['AAAZ_associatede']);
    update_option('AAAZ_associatefr',$_POST['AAAZ_associatefr']);
    update_option('AAAZ_associatejp',$_POST['AAAZ_associatejp']);
    update_option('AAAZ_associateuk',$_POST['AAAZ_associateuk']);
    update_option('AAAZ_associateca',$_POST['AAAZ_associateca']);
    update_option('AAebay_on',$_POST['AAebay_on']);
    update_option('AAebay_campaign_id',$_POST['AAebay_campaign_id']);
    echo '<div id="message" class="update"><strong>Action Affiliate Settings Updated</strong></div>';
  }
?>
<div class="wrap">
<h3>Action Affiliate Settings</h3><span style="float:right; padding:3px;"><h3>Find this useful?</h3><p><form action="https://www.paypal.com/cgi-bin/webscr" method="post">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="6T4Q23QUD3JWQ">
<input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
<img alt="" border="0" src="https://www.paypalobjects.com/en_US/i/scr/pixel.gif" width="1" height="1">
</form>
</p></span>
<form method="post">
<table cellspacing="10" cellpadding="5">
<tr>                          <td>
<strong>Amount of Ads to Appear for all programs</strong> </td>
<td>
<input name="AACJ_cj_amount" type="text" id="AACJ_cj_amount" value="<?php echo get_option('AACJ_cj_amount'); ?>"/>
</td>
</tr>
<tr>
<td>
<h3>CJ Settings</h3>
</td>
</tr>
<tr>
<td>
Display CJ Ads:</td><td>
<?php
$cjon = get_option('AACJ_on');
if ($cjon == 1){
  echo '<input name="AACJ_on" type="radio" value="1" checked="checked" />Yes     <input name="AACJ_on" type="radio" value="0" />No';
}
else {
  echo '<input name="AACJ_on" type="radio" value="1" />Yes     <input name="AACJ_on" type="radio" value="0" checked="checked" />No';
}
?>
</td>
</tr>
<tr>
<td>
<strong><a href="http://cj.com" target="_blank">CJ Website ID:</a></strong>
</td>
<td>
<input name="AACJ_websiteid" type="text" id="AACJ_websiteid" value="<?php echo get_option('AACJ_websiteid'); ?>" maxlength="30" />
</td>
</tr>
<tr>
<td>
<a href="http://webservices.cj.com" target="_blank"><strong>CJ Webservices Developer Key:</strong></a>
</td>
<td>
<input name="AACJ_CJ_DevKey" type="text" id="AACJ_CJ_DevKey" value="<?php echo get_option('AACJ_CJ_DevKey'); ?>"/>
</td>
</tr>
<tr>
<td>
<h3>Amazon Settings</h3>
</td>
</tr>
<tr>
<td>
Display Amazon Ads:</td><td>
<?php
$azon = get_option('AAAZ_on');
if ($azon == 1){
  echo '<input name="AAAZ_on" type="radio" value="1" checked="checked" />Yes     <input name="AAAZ_on" type="radio" value="0" />No';
}
else {
  echo '<input name="AAAZ_on" type="radio" value="1" />Yes     <input name="AAAZ_on" type="radio" value="0" checked="checked" />No';
}
?>
</td>
</tr>
<tr>
<td>
<strong><a href="https://affiliate-program.amazon.com/gp/advertising/api/detail/main.html" target="_blank">Amazon Webservices Public Key</a></strong>
</td>
<td>
<input name="AAAZ_public_key" type="text" id="AAAZ_public_key" value="<?php echo get_option('AAAZ_public_key'); ?>"/>
</td>
</tr>
<tr>
<td>
Amazon Webservices Private Key
</td>
<td>
<input type="text" name="AAAZ_private_key" id="AAAZ_private_key" value="<?php echo get_option('AAAZ_private_key'); ?>"/>
</td>
</tr>
<tr>
<td>
Amazon US Associate ID
</td>
<td>
<input type="text" name="AAAZ_associateus" id="AAAZ_associateus" value="<?php echo get_option('AAAZ_associateus'); ?>"/>
</td>
</tr>
<!--**********************************************************
THIS IS FOR A FUTURE RELEASE VERSION
<tr>
<td>
Amazon DE Associate ID
</td>
<td>
<input type="text" name="AAAZ_associatede" id="AAAZ_associatede" value="<?php echo get_option('AAAZ_associatede'); ?>"/>
</td>
</tr>
<tr>
<td>
Amazon FR Associate ID
</td>
<td>
<input type="text" name="AAAZ_associatefr" id="AAAZ_associatefr" value="<?php echo get_option('AAAZ_associatefr'); ?>"/>
</td>
</tr>
<tr>
<td>
Amazon JP Associate ID
</td>
<td>
<input type="text" name="AAAZ_associatejp" id="AAAZ_associatejp" value="<?php echo get_option('AAAZ_associatejp'); ?>"/>
</td>
</tr>
<tr>
<td>
Amazon UK Associate ID
</td>
<td>
<input type="text" name="AAAZ_associateuk" id="AAAZ_associateuk" value="<?php echo get_option('AAAZ_associateuk'); ?>"/>
</td>
</tr>
<tr>
<td>
Amazon CA Associate ID
</td>
<td>
<input type="text" name="AAAZ_associateca" id="AAAZ_associateca" value="<?php echo get_option('AAAZ_associateca'); ?>"/>
</td>
</tr>
**************************************************************************-->
<tr>
<td>
<h3>eBay Settings</h3>
</td>
</tr>
<tr>
<td>
Display eBay Ads:</td><td>
<?php
$ebayon = get_option('AAebay_on');
if ($ebayon == 1){
  echo '<input name="AAebay_on" type="radio" value="1" checked="checked" />Yes     <input name="AAebay_on" type="radio" value="0" />No';
}
else {
  echo '<input name="AAebay_on" type="radio" value="1" />Yes     <input name="AAebay_on" type="radio" value="0" checked="checked" />No';
}
?>
</td>
</tr>
<tr>
<td>
eBay Partner Network Campaign ID:
</td>
<td>
<input type="text" name="AAebay_campaign_id" id="AAebay_campaign_id" value="<?php echo get_option('AAebay_campaign_id'); ?>"/>
</td>
</tr>
</table>
<p class="submit"><input type="submit" name="aa_updated" value="Update Settings &raquo;" /></p>
</form>
<h2>Instructions for adding comparison shopping to post</h2>
<p>At the end of the post, insert the following code:<br/>
[aa keywords=""]</p>
<p>Action Affiliate will then add relevant ads from your chosen networks to your post!</p>
<?php
  $myFile = "../go.php";
  $fh = fopen($myFile, 'w');
  fwrite($fh, '<'.chr(63).'php
  $link = $_POST[\'link\'];
header ("Location: $link");
exit();
'.chr(63).'>');
fclose($fh);
?>
</div>
</div>
<?php
}
add_shortcode('aa','AA_shortcode');
add_action('admin_menu', 'add_actionaffiliate_panel');
?>