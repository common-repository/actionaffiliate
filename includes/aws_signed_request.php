<?php
function aws_signed_request($region, $params, $api_key, $private_key)
{
    $method = "GET";
    $host = "ecs.amazonaws.com";
    $uri = "/onca/xml";
    $params["Service"] = "AWSECommerceService";
    $params["AWSAccessKeyId"] = $api_key;
    $params["Timestamp"] = gmdate("Y-m-d\TH:i:s\Z",time());  //may not be more than 15 minutes out of date!
    $params["Version"] = "2009-03-31";
    ksort($params);
    $canonicalized_query = array();
    foreach ($params as $param=>$value)
    {
        $param = str_replace("%7E", "~", rawurlencode($param));
        $value = str_replace("%7E", "~", rawurlencode($value));
        $canonicalized_query[] = $param."=".$value;
    }
    $canonicalized_query = implode("&", $canonicalized_query);
    $string_to_sign = $method."\n".$host."\n".$uri."\n".$canonicalized_query;
    $signature = base64_encode(hash_hmac("sha256", $string_to_sign, $private_key, True));
    $signature = rawurlencode($signature);

    // create request
    $request = "http://".$host.$uri."?".$canonicalized_query."&Signature=".$signature;
    return $request;
}