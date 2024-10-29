<?php

// Action Affiliate eBay Module

//Copyright © 2010 phpPig.org, phpAffiliateScript.com

$display = $list;

if ($display==''){$display=1;}

if($newwindow!=='1'){$newwindow='target="_blank" ';}

if ($epn_campaign_id==''){$epn_campaign_id='00000';}

$customid = str_replace(' ','+',$customid);

if ($customid==''){$customid='ActionAffiliate';}

if ($coutry1 == '1')

 { $country = 'au';}

elseif ($country1 == '2')

 { $country = 'at';}

elseif ($country1 == '3')

 { $country = 'benl';}

elseif ($country1 == '4')

 { $country = 'befr';}

elseif ($country1 == '5')

 { $country = 'ca';}

elseif ($country1 == '6')

 { $country = 'cafr';}

elseif ($country1 == '7')

 { $country = 'cn';}

elseif ($country1 == '8')

 { $country = 'fr';}

elseif ($country1 == '9')

 { $country = 'de';}

elseif ($country1 == '10')

 { $country = 'hk';}

elseif ($country1 == '11')

 { $country = 'in';}

elseif ($country1 == '12')

 { $country = 'ie';}

elseif ($country1 == '13')

 { $country = 'it';}

elseif ($country1 == '14')

 { $country = 'my';}

elseif ($country1 == '15')

 { $country = 'nl';}

elseif ($country1 == '16')

 { $country = 'ph';}

elseif ($country1 == '17')

 { $country = 'pl';}

elseif ($country1 == '18')

 { $country = 'sg';}

elseif ($country1 == '19')

 { $country = 'es';}

elseif ($country1 == '20')

 { $country = 'se';}

elseif ($country1 == '21')

 { $country = 'ch';}

elseif ($country1 == '22')

 { $country = 'tw';}

elseif ($country1 == '23')

 { $country = 'uk';}

elseif ($country1 == '24')

 { $country = 'us';}

elseif ($country1 == '25')

 { $country = 'motors';}

if ($country==''){$geo=0;}

if ($country=='us'){$geo=0;}

if ($country=='au'){$geo=15;}

if ($country=='at'){$geo=16;}

if ($country=='benl'){$geo=123;}

if ($country=='befr'){$geo=23;}

if ($country=='ca'){$geo=2;}

if ($country=='cafr'){$geo=210;}

if ($country=='cn'){$geo=223;}

if ($country=='fr'){$geo=71;}

if ($country=='de'){$geo=77;} 

if ($country=='hk'){$geo=201;}

if ($country=='in'){$geo=203;}

if ($country=='ie'){$geo=205;}

if ($country=='it'){$geo=101;}

if ($country=='my'){$geo=207;}

if ($country=='nl'){$geo=146;}

if ($country=='ph'){$geo=211;}

if ($country=='pl'){$geo=212;}

if ($country=='sg'){$geo=216;}

if ($country=='es'){$geo=186;}

if ($country=='ch'){$geo=193;}

if ($country=='tw'){$geo=196;}

if ($country=='uk'){$geo=3;}

if ($country=='motors'){$geo=100;}

$ebayword = str_replace(' ', '+', $ebayword);

$link = 'http://rss.api.ebay.com/ws/rssapi?FeedName=SearchResults&siteId='.$geo.'&language=en-US&output=RSS20&sacqy=&catref=C5&sacur=0&from=R6&saobfmts=exsif&dfsp=32&afepn='.$epn_campaign_id.'&sacqyop=ge&saslc=0&floc=1&sabfmts=0&saprclo=&saprchi=&saaff=afepn&ftrv=1&ftrt=1&fcl=3&frpp=50&customid='.$customid.'&nojspr=yZQy&satitle='.$ebayword.'&afmp=&sacat=-1&saslop=1&fss=0';

$rsscount = null;

include_once './wp-content/plugins/ActionAffiliate/includes/lastRSS.php';

$rss = new lastRSS;

$rss->cache_dir = './cache';

$rss->cache_time = 3600; // one hour

if ($rs = $rss->get($link)) {

foreach ($rs['items'] as $item) {

$rsscount++;

if (($rsscount < ($display+1))) {

$ebay1= $item['link'];

$ebay2 = $item['description'];

$ebay = '<a  href="'.$ebay1.'" '.$newwindow.'><b>'.$item[title].'</b></a>'.$ebay2.'<hr size="1" noshade="noshade" />';

$ebay = str_replace('<a', '<a title="'.$item[title].'"' , $ebay);

$ebay = str_replace('jpg">', 'jpg" />', $ebay);

$ebay = str_replace('&customid', '&amp;customid', $ebay);

$ebay = str_replace('&toolid', '&amp;toolid', $ebay);

$ebay = str_replace('&mpre', '&amp;mpre', $ebay);

$l1 .= $ebay;

}}

}

?>