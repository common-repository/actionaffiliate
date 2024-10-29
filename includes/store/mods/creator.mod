# version:		1.070925
# copyright:	MrRat - http://www.mrrat.com
# license:		GPL - http://www.opensource.org/licenses/gpl-license.html
# purpose:		mod for APF
# description:	add Illustrator variable
#
use strict vars;

my ($my_marketplace_text, $my_ThirdPartyProductDetails);
our %subs__creator = ( assign_variables_Details_loop => "Yes" );

sub assign_variables_Details_loop__creator {
	if ($AWS_variables{ItemAttributes} =~ /<Creator Role="Illustrator">([^<]+)<\/Creator>/) {
		$MY_variables{Illustrator} = "<span class=\"apf_heading4\">Illustrator:</span> $1<br />\n";
		$MY_variables{my_descriptors} .= $MY_variables{Illustrator};
	}
}

