<?php
$api_key = get_option('AAAZ_public_key');

$private_key = get_option('AAAZ_private_key');
$timestamp = gmdate('Y-m-d\TH:i:s\Z');
$list = get_option('AACJ_cj_amount');
$ext = get_option('AAAZ_locale');
if ($ext == 'com'){
$associate = get_option('AAAZ_associateus'); 
}
/* FUTURE RELEASE WILL ACTIVATE THESE SETTINGS!
elseif ($ext == 'co.jp'){
  $associate = get_option('AAAZ_associatejp');
}
elseif ($ext == 'fr'){
  $associate = get_option('AAAZ_associatefr');
}
elseif ($ext == 'ca'){
  $associate = get_option('AAAZ_associateca');
}
elseif ($ext == 'co.uk'){
  $associate = get_option('AAAZ_associateuk');
}
elseif ($ext == 'de') {
  $associate = get_option('AAAZ_associatede');
} 
*/
$SearchIndex = 'All';
$ResponseGroup = 'ItemAttributes,Offers,Medium';
$parameters ["AWSAccessKeyId"] = $api_key;
$parameters ['AssociateTag'] = $associate;
$parameters ['Keywords'] = $keywords;
$parameters ['Operation'] = 'ItemSearch';
$parameters ['SearchIndex']= $SearchIndex;
$parameters ['Service'] ='AWSECommerceService';
//request.Condition = Condition.All;
//request.ConditionSpecified = true;
//request.Keywords = "";
$parameters ['Count'] =$list;
$parameters ['Timestamp'] =$timestamp;
$parameters ['Version'] ='2009-03-31';
$parameters ['ResponseGroup'] = $ResponseGroup;
require_once "aws_signed_request.php";
  $file=aws_signed_request($ext,$parameters,$api_key,$private_key);
$az1 = curl_init($file);
 curl_setopt($az1, CURLOPT_POST, FAlSE);
 curl_setopt($az1, CURLOPT_SSL_VERIFYPEER, FALSE);
 curl_setopt($az1, CURLOPT_RETURNTRANSFER, TRUE);
 $AZ = curl_exec($az1);
 curl_close($az1);  
 //file_get_contents doesn't work on 1&1 Shared Servers -> Curl implemented this version
 //$AZ = file_get_contents($file);
  $parsed_xml = simplexml_load_string($AZ);

		foreach($parsed_xml->Items->Item as $current){

        				$picture = $current->MediumImage->URL;
				$azname = $current->ItemAttributes->Title;
				$azprice = $current->Offers->Offer->OfferListing->Price->FormattedPrice;
				$asin = $current->ASIN;
				$offerListingId = urlencode($current->Offers->Offer->OfferListing->OfferListingId);
        $azdescription = $current->EditorialReviews->EditorialReview->Content;
        $azlink = $current->DetailPageURL;
        $availability = $current->Offers->Offer->Availability;
        //$azjump = seo_str($azlink);
$l1 .= '<table border="0"><tr><td><h2><font size="3">'.$azname.'</font></h2></a><br><font size="2"><b>'.$azprice.' </font></b><br><img src="'.$picture.'" title="'.$azname.'" border="0"></a><br>'.$azdescription.' <br></td></tr>
<tr><td><a href="'.$azlink.'"><img src="'.$siteurl.'/wp-content/plugins/ActionAffiliate/images/more.jpg" /></a>
</td></tr></table> ';




           }
?>