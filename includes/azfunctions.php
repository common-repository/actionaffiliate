<?php

    function seo_str($string)

 {

      $string = html_entity_decode($string, ENT_QUOTES);

      $string = ereg_replace("[^a-zA-Z0-9 ]", "", $string);

      $string = ereg_replace(" +", " ", $string);

      $string = str_replace(" ", "_", $string);

     /* $string = str_replace("-","_",$string);  */

      return $string;

  }

?>