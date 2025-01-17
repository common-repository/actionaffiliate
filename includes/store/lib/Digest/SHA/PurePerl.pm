package Digest::SHA::PurePerl;

require 5.003000;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use integer;
use FileHandle;

$VERSION='5.47';

require Exporter;
@ISA=qw(Exporter);
@EXPORT_OK=();

*addfile=\&_Addfile;

eval{
require MIME::Base64;
require Digest::base;
push(@ISA, 'Digest::base');
};
if($@){
*hexdigest=\&_Hexdigest;
*b64digest=\&_B64digest;
}

my $MAX32=0xffffffff;
my $TWO32=4294967296;
my $uses64bit=(((1 << 16) << 16) << 16) << 15;
my @H01=(
0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476,
0xc3d2e1f0
);
my @H0224=(
0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939,
0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4
);

my @H0256=(
0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
);
my(@H0384, @H0512);

sub _c_SL32{
my($x, $n)=@_;
"($x << $n)";
}

sub _c_SR32{
my($x, $n)=@_;
my $mask=(1 << (32 - $n)) - 1;
"(($x >> $n) & $mask)";
}

sub _c_Ch{my($x, $y, $z)=@_; "($z ^ ($x & ($y ^ $z)))" }
sub _c_Pa{my($x, $y, $z)=@_; "($x ^ $y ^ $z)" }
sub _c_Ma{my($x, $y, $z)=@_; "(($x & $y) | ($z & ($x | $y)))" }

sub _c_ROTR{my($x, $n)=@_;
"(" . _c_SR32($x, $n) . " | " . _c_SL32($x, 32 - $n) . ")";
}

sub _c_ROTL{my($x, $n)=@_;
"(" . _c_SL32($x, $n) . " | " . _c_SR32($x, 32 - $n) . ")";
}

sub _c_SIGMA0{my($x)=@_;
"(" . _c_ROTR($x,  2) . " ^ " . _c_ROTR($x, 13) . " ^ " .
_c_ROTR($x, 22) . ")";
}

sub _c_SIGMA1{my($x)=@_;
"(" . _c_ROTR($x,  6) . " ^ " . _c_ROTR($x, 11) . " ^ " .
_c_ROTR($x, 25) . ")";
}

sub _c_sigma0{my($x)=@_;
"(" . _c_ROTR($x,  7) . " ^ " . _c_ROTR($x, 18) . " ^ " .
_c_SR32($x,  3) . ")";
}

sub _c_sigma1{my($x)=@_;
"(" . _c_ROTR($x, 17) . " ^ " . _c_ROTR($x, 19) . " ^ " .
_c_SR32($x, 10) . ")";
}

sub _c_M1Ch{my($a, $b, $c, $d, $e, $k, $w)=@_;
"$e += " . _c_ROTL($a, 5) . " + " . _c_Ch($b, $c, $d) .
" + $k + $w; $b=" . _c_ROTL($b, 30) . ";\n";
}

sub _c_M1Pa{my($a, $b, $c, $d, $e, $k, $w)=@_;
"$e += " . _c_ROTL($a, 5) . " + " . _c_Pa($b, $c, $d) .
" + $k + $w; $b=" . _c_ROTL($b, 30) . ";\n";
}

sub _c_M1Ma {
my($a, $b, $c, $d, $e, $k, $w)=@_;
"$e += " . _c_ROTL($a, 5) . " + " . _c_Ma($b, $c, $d) .
" + $k + $w; $b=" . _c_ROTL($b, 30) . ";\n";
}

sub _c_M11Ch{my($k, $w)=@_; _c_M1Ch('$a', '$b', '$c', '$d', '$e', $k, $w)}
sub _c_M11Pa{my($k, $w)=@_; _c_M1Pa('$a', '$b', '$c', '$d', '$e', $k, $w)}
sub _c_M11Ma{my($k, $w)=@_; _c_M1Ma('$a', '$b', '$c', '$d', '$e', $k, $w)}
sub _c_M12Ch{my($k, $w)=@_; _c_M1Ch('$e', '$a', '$b', '$c', '$d', $k, $w)}
sub _c_M12Pa{my($k, $w)=@_; _c_M1Pa('$e', '$a', '$b', '$c', '$d', $k, $w)}
sub _c_M12Ma{my($k, $w)=@_; _c_M1Ma('$e', '$a', '$b', '$c', '$d', $k, $w)}
sub _c_M13Ch{my($k, $w)=@_; _c_M1Ch('$d', '$e', '$a', '$b', '$c', $k, $w)}
sub _c_M13Pa{my($k, $w)=@_; _c_M1Pa('$d', '$e', '$a', '$b', '$c', $k, $w)}
sub _c_M13Ma{my($k, $w)=@_; _c_M1Ma('$d', '$e', '$a', '$b', '$c', $k, $w)}
sub _c_M14Ch{my($k, $w)=@_; _c_M1Ch('$c', '$d', '$e', '$a', '$b', $k, $w)}
sub _c_M14Pa{my($k, $w)=@_; _c_M1Pa('$c', '$d', '$e', '$a', '$b', $k, $w)}
sub _c_M14Ma{my($k, $w)=@_; _c_M1Ma('$c', '$d', '$e', '$a', '$b', $k, $w)}
sub _c_M15Ch{my($k, $w)=@_; _c_M1Ch('$b', '$c', '$d', '$e', '$a', $k, $w)}
sub _c_M15Pa{my($k, $w)=@_; _c_M1Pa('$b', '$c', '$d', '$e', '$a', $k, $w)}
sub _c_M15Ma{my($k, $w)=@_; _c_M1Ma('$b', '$c', '$d', '$e', '$a', $k, $w)}

sub _c_W11{my($s)=@_; '$W[' . (($s +  0) & 0xf) . ']' }
sub _c_W12{my($s)=@_; '$W[' . (($s + 13) & 0xf) . ']' }
sub _c_W13{my($s)=@_; '$W[' . (($s +  8) & 0xf) . ']' }
sub _c_W14{my($s)=@_; '$W[' . (($s +  2) & 0xf) . ']' }

sub _c_A1{my($s)=@_;
my $tmp=_c_W11($s) . " ^ " . _c_W12($s) . " ^ " .
_c_W13($s) . " ^ " . _c_W14($s);
"((\$tmp=$tmp), (" . _c_W11($s) . "=" . _c_ROTL('$tmp', 1) . "))";
}
my $sha1_code='
my($K1, $K2, $K3, $K4)=(
0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xca62c1d6
);

sub _sha1{my($self, $block)=@_;
my(@W, $a, $b, $c, $d, $e, $tmp);
@W=unpack("N16", $block);
($a, $b, $c, $d, $e)=@{$self->{H}};
' .
_c_M11Ch('$K1', '$W[ 0]'  ) . _c_M12Ch('$K1', '$W[ 1]'  ) .
_c_M13Ch('$K1', '$W[ 2]'  ) . _c_M14Ch('$K1', '$W[ 3]'  ) .
_c_M15Ch('$K1', '$W[ 4]'  ) . _c_M11Ch('$K1', '$W[ 5]'  ) .
_c_M12Ch('$K1', '$W[ 6]'  ) . _c_M13Ch('$K1', '$W[ 7]'  ) .
_c_M14Ch('$K1', '$W[ 8]'  ) . _c_M15Ch('$K1', '$W[ 9]'  ) .
_c_M11Ch('$K1', '$W[10]'  ) . _c_M12Ch('$K1', '$W[11]'  ) .
_c_M13Ch('$K1', '$W[12]'  ) . _c_M14Ch('$K1', '$W[13]'  ) .
_c_M15Ch('$K1', '$W[14]'  ) . _c_M11Ch('$K1', '$W[15]'  ) .
_c_M12Ch('$K1', _c_A1( 0) ) . _c_M13Ch('$K1', _c_A1( 1) ) .
_c_M14Ch('$K1', _c_A1( 2) ) . _c_M15Ch('$K1', _c_A1( 3) ) .
_c_M11Pa('$K2', _c_A1( 4) ) . _c_M12Pa('$K2', _c_A1( 5) ) .
_c_M13Pa('$K2', _c_A1( 6) ) . _c_M14Pa('$K2', _c_A1( 7) ) .
_c_M15Pa('$K2', _c_A1( 8) ) . _c_M11Pa('$K2', _c_A1( 9) ) .
_c_M12Pa('$K2', _c_A1(10) ) . _c_M13Pa('$K2', _c_A1(11) ) .
_c_M14Pa('$K2', _c_A1(12) ) . _c_M15Pa('$K2', _c_A1(13) ) .
_c_M11Pa('$K2', _c_A1(14) ) . _c_M12Pa('$K2', _c_A1(15) ) .
_c_M13Pa('$K2', _c_A1( 0) ) . _c_M14Pa('$K2', _c_A1( 1) ) .
_c_M15Pa('$K2', _c_A1( 2) ) . _c_M11Pa('$K2', _c_A1( 3) ) .
_c_M12Pa('$K2', _c_A1( 4) ) . _c_M13Pa('$K2', _c_A1( 5) ) .
_c_M14Pa('$K2', _c_A1( 6) ) . _c_M15Pa('$K2', _c_A1( 7) ) .
_c_M11Ma('$K3', _c_A1( 8) ) . _c_M12Ma('$K3', _c_A1( 9) ) .
_c_M13Ma('$K3', _c_A1(10) ) . _c_M14Ma('$K3', _c_A1(11) ) .
_c_M15Ma('$K3', _c_A1(12) ) . _c_M11Ma('$K3', _c_A1(13) ) .
_c_M12Ma('$K3', _c_A1(14) ) . _c_M13Ma('$K3', _c_A1(15) ) .
_c_M14Ma('$K3', _c_A1( 0) ) . _c_M15Ma('$K3', _c_A1( 1) ) .
_c_M11Ma('$K3', _c_A1( 2) ) . _c_M12Ma('$K3', _c_A1( 3) ) .
_c_M13Ma('$K3', _c_A1( 4) ) . _c_M14Ma('$K3', _c_A1( 5) ) .
_c_M15Ma('$K3', _c_A1( 6) ) . _c_M11Ma('$K3', _c_A1( 7) ) .
_c_M12Ma('$K3', _c_A1( 8) ) . _c_M13Ma('$K3', _c_A1( 9) ) .
_c_M14Ma('$K3', _c_A1(10) ) . _c_M15Ma('$K3', _c_A1(11) ) .
_c_M11Pa('$K4', _c_A1(12) ) . _c_M12Pa('$K4', _c_A1(13) ) .
_c_M13Pa('$K4', _c_A1(14) ) . _c_M14Pa('$K4', _c_A1(15) ) .
_c_M15Pa('$K4', _c_A1( 0) ) . _c_M11Pa('$K4', _c_A1( 1) ) .
_c_M12Pa('$K4', _c_A1( 2) ) . _c_M13Pa('$K4', _c_A1( 3) ) .
_c_M14Pa('$K4', _c_A1( 4) ) . _c_M15Pa('$K4', _c_A1( 5) ) .
_c_M11Pa('$K4', _c_A1( 6) ) . _c_M12Pa('$K4', _c_A1( 7) ) .
_c_M13Pa('$K4', _c_A1( 8) ) . _c_M14Pa('$K4', _c_A1( 9) ) .
_c_M15Pa('$K4', _c_A1(10) ) . _c_M11Pa('$K4', _c_A1(11) ) .
_c_M12Pa('$K4', _c_A1(12) ) . _c_M13Pa('$K4', _c_A1(13) ) .
_c_M14Pa('$K4', _c_A1(14) ) . _c_M15Pa('$K4', _c_A1(15) ) .

'$self->{H}->[0] += $a; $self->{H}->[1] += $b; $self->{H}->[2] += $c;
$self->{H}->[3] += $d; $self->{H}->[4] += $e;
}
';

eval($sha1_code);

sub _c_M2 {
my($a, $b, $c, $d, $e, $f, $g, $h, $w)=@_;
"\$T1=$h + " . _c_SIGMA1($e) . " + " . _c_Ch($e, $f, $g) .
" + \$K256[\$i++] + $w; $h=\$T1 + " . _c_SIGMA0($a) .
" + " . _c_Ma($a, $b, $c) . "; $d += \$T1;\n";
}

sub _c_M21 { _c_M2('$a', '$b', '$c', '$d', '$e', '$f', '$g', '$h', $_[0])}
sub _c_M22 { _c_M2('$h', '$a', '$b', '$c', '$d', '$e', '$f', '$g', $_[0])}
sub _c_M23 { _c_M2('$g', '$h', '$a', '$b', '$c', '$d', '$e', '$f', $_[0])}
sub _c_M24 { _c_M2('$f', '$g', '$h', '$a', '$b', '$c', '$d', '$e', $_[0])}
sub _c_M25 { _c_M2('$e', '$f', '$g', '$h', '$a', '$b', '$c', '$d', $_[0])}
sub _c_M26 { _c_M2('$d', '$e', '$f', '$g', '$h', '$a', '$b', '$c', $_[0])}
sub _c_M27 { _c_M2('$c', '$d', '$e', '$f', '$g', '$h', '$a', '$b', $_[0])}
sub _c_M28 { _c_M2('$b', '$c', '$d', '$e', '$f', '$g', '$h', '$a', $_[0])}

sub _c_W21 {my($s)=@_; '$W[' . (($s +  0) & 0xf) . ']' }
sub _c_W22 {my($s)=@_; '$W[' . (($s + 14) & 0xf) . ']' }
sub _c_W23 {my($s)=@_; '$W[' . (($s +  9) & 0xf) . ']' }
sub _c_W24{my($s)=@_; '$W[' . (($s +  1) & 0xf) . ']' }

sub _c_A2{
my($s)=@_;
"(" . _c_W21($s) . " += " . _c_sigma1(_c_W22($s)) . " + " .
_c_W23($s) . " + " . _c_sigma0(_c_W24($s)) . ")";
}
my $sha256_code='
my @K256=(
0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
);

sub _sha256 {
my($self, $block)=@_;
my(@W, $a, $b, $c, $d, $e, $f, $g, $h, $i, $T1);

@W=unpack("N16", $block);
($a, $b, $c, $d, $e, $f, $g, $h)=@{$self->{H}};
' .
_c_M21('$W[ 0]' ) . _c_M22('$W[ 1]' ) . _c_M23('$W[ 2]' ) .
_c_M24('$W[ 3]' ) . _c_M25('$W[ 4]' ) . _c_M26('$W[ 5]' ) .
_c_M27('$W[ 6]' ) . _c_M28('$W[ 7]' ) . _c_M21('$W[ 8]' ) .
_c_M22('$W[ 9]' ) . _c_M23('$W[10]' ) . _c_M24('$W[11]' ) .
_c_M25('$W[12]' ) . _c_M26('$W[13]' ) . _c_M27('$W[14]' ) .
_c_M28('$W[15]' ) .
_c_M21(_c_A2( 0)) . _c_M22(_c_A2( 1)) . _c_M23(_c_A2( 2)) .
_c_M24(_c_A2( 3)) . _c_M25(_c_A2( 4)) . _c_M26(_c_A2( 5)) .
_c_M27(_c_A2( 6)) . _c_M28(_c_A2( 7)) . _c_M21(_c_A2( 8)) .
_c_M22(_c_A2( 9)) . _c_M23(_c_A2(10)) . _c_M24(_c_A2(11)) .
_c_M25(_c_A2(12)) . _c_M26(_c_A2(13)) . _c_M27(_c_A2(14)) .
_c_M28(_c_A2(15)) . _c_M21(_c_A2( 0)) . _c_M22(_c_A2( 1)) .
_c_M23(_c_A2( 2)) . _c_M24(_c_A2( 3)) . _c_M25(_c_A2( 4)) .
_c_M26(_c_A2( 5)) . _c_M27(_c_A2( 6)) . _c_M28(_c_A2( 7)) .
_c_M21(_c_A2( 8)) . _c_M22(_c_A2( 9)) . _c_M23(_c_A2(10)) .
_c_M24(_c_A2(11)) . _c_M25(_c_A2(12)) . _c_M26(_c_A2(13)) .
_c_M27(_c_A2(14)) . _c_M28(_c_A2(15)) . _c_M21(_c_A2( 0)) .
_c_M22(_c_A2( 1)) . _c_M23(_c_A2( 2)) . _c_M24(_c_A2( 3)) .
_c_M25(_c_A2( 4)) . _c_M26(_c_A2( 5)) . _c_M27(_c_A2( 6)) .
_c_M28(_c_A2( 7)) . _c_M21(_c_A2( 8)) . _c_M22(_c_A2( 9)) .
_c_M23(_c_A2(10)) . _c_M24(_c_A2(11)) . _c_M25(_c_A2(12)) .
_c_M26(_c_A2(13)) . _c_M27(_c_A2(14)) . _c_M28(_c_A2(15)) .

'$self->{H}->[0] += $a; $self->{H}->[1] += $b; $self->{H}->[2] += $c;
$self->{H}->[3] += $d; $self->{H}->[4] += $e; $self->{H}->[5] += $f;
$self->{H}->[6] += $g; $self->{H}->[7] += $h;
}
';

eval($sha256_code);

sub _sha512_placeholder{return}
my $sha512=\&_sha512_placeholder;
my $_64bit_code='
my $w_flag;

BEGIN{
$w_flag=$^W;
$^W=0;
}

my @K512=(
0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f,
0xe9b5dba58189dbbc, 0x3956c25bf348b538, 0x59f111f1b605d019,
0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242,
0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,
0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3,
0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65, 0x2de92c6f592b0275,
0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f,
0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,
0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc,
0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6,
0x92722c851482353b, 0xa2bfe8a14cf10364, 0xa81a664bbc423001,
0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218,
0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99,
0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb,
0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc,
0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915,
0xc67178f2e372532b, 0xca273eceea26619c, 0xd186b8c721c0c207,
0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba,
0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,
0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a,
0x5fcb6fab3ad6faec, 0x6c44198c4a475817);

@H0384=(
0xcbbb9d5dc1059ed8, 0x629a292a367cd507, 0x9159015a3070dd17,
0x152fecd8f70e5939, 0x67332667ffc00b31, 0x8eb44a8768581511,
0xdb0c2e0d64f98fa7, 0x47b5481dbefa4fa4);

@H0512=(
0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b,
0xa54ff53a5f1d36f1, 0x510e527fade682d1, 0x9b05688c2b3e6c1f,
0x1f83d9abfb41bd6b, 0x5be0cd19137e2179);

BEGIN { $^W=$w_flag }

sub _c_SL64{my($x, $n)=@_; "($x << $n)" }

sub _c_SR64{my($x, $n)=@_;
my $mask=(1 << (64 - $n)) - 1;
"(($x >> $n) & $mask)";
}

sub _c_ROTRQ{my($x, $n)=@_;
"(" . _c_SR64($x, $n) . " | " . _c_SL64($x, 64 - $n) . ")";
}

sub _c_SIGMAQ0{my($x)=@_;
"(" . _c_ROTRQ($x, 28) . " ^ " .  _c_ROTRQ($x, 34) . " ^ " .
_c_ROTRQ($x, 39) . ")";
}

sub _c_SIGMAQ1{my($x)=@_;
"(" . _c_ROTRQ($x, 14) . " ^ " .  _c_ROTRQ($x, 18) . " ^ " .
_c_ROTRQ($x, 41) . ")";
}

sub _c_sigmaQ0{my($x)=@_;
"(" . _c_ROTRQ($x, 1) . " ^ " .  _c_ROTRQ($x, 8) . " ^ " .
_c_SR64($x, 7) . ")";
}

sub _c_sigmaQ1{my($x)=@_;
"(" . _c_ROTRQ($x, 19) . " ^ " .  _c_ROTRQ($x, 61) . " ^ " .
_c_SR64($x, 6) . ")";
}
my $sha512_code=q/
sub _sha512 {
my($self, $block)=@_;
my(@N, @W, $a, $b, $c, $d, $e, $f, $g, $h, $T1, $T2);

@N=unpack("N32", $block);
($a, $b, $c, $d, $e, $f, $g, $h)=@{$self->{H}};
for ( 0 .. 15){ $W[$_]=(($N[2*$_] << 16) << 16) | $N[2*$_+1] }
for (16 .. 79){ $W[$_]=/ .
_c_sigmaQ1(q/$W[$_- 2]/) . q/ + $W[$_- 7] + / .
_c_sigmaQ0(q/$W[$_-15]/) . q/ + $W[$_-16] }
for ( 0 .. 79){
$T1=$h + / . _c_SIGMAQ1(q/$e/) .
q/ + (($g) ^ (($e) & (($f) ^ ($g)))) +
$K512[$_] + $W[$_];
$T2=/ . _c_SIGMAQ0(q/$a/) .
q/ + ((($a) & ($b)) | (($c) & (($a) | ($b))));
$h=$g; $g=$f; $f=$e; $e=$d + $T1;
$d=$c; $c=$b; $b=$a; $a=$T1 + $T2;
}
$self->{H}->[0] += $a; $self->{H}->[1] += $b; $self->{H}->[2] += $c;
$self->{H}->[3] += $d; $self->{H}->[4] += $e; $self->{H}->[5] += $f;
$self->{H}->[6] += $g; $self->{H}->[7] += $h;
}
/;

eval($sha512_code);
$sha512=\&_sha512;

';

eval($_64bit_code) if $uses64bit;

sub _SETBIT {
my($self, $pos)=@_;
my @c=unpack("C*", $self->{block});
$c[$pos >> 3]=0x00 unless defined $c[$pos >> 3];
$c[$pos >> 3] |= (0x01 << (7 - $pos % 8));
$self->{block}=pack("C*", @c);
}

sub _CLRBIT {
my($self, $pos)=@_;
my @c=unpack("C*", $self->{block});
$c[$pos >> 3]=0x00 unless defined $c[$pos >> 3];
$c[$pos >> 3] &= ~(0x01 << (7 - $pos % 8));
$self->{block}=pack("C*", @c);
}

sub _BYTECNT {
my($bitcnt)=@_;
$bitcnt > 0 ? 1 + (($bitcnt - 1) >> 3) : 0;
}

sub _digcpy {
my($self)=@_;
my @dig;
for (@{$self->{H}}){
push(@dig, (($_>>16)>>16) & $MAX32) if $self->{alg} >= 384;
push(@dig, $_ & $MAX32);
}
$self->{digest}=pack("N" . ($self->{digestlen}>>2), @dig);
}

sub _sharewind{
my($self)=@_;
my $alg=$self->{alg};
$self->{block}=""; $self->{blockcnt}=0;
$self->{blocksize}=$alg <= 256 ? 512 : 1024;
for (qw(lenll lenlh lenhl lenhh)){ $self->{$_}=0 }
$self->{digestlen}=$alg == 1 ? 20 : $alg/8;
if    ($alg == 1)   { $self->{sha}=\&_sha1;   $self->{H}=[@H01]   }
elsif($alg == 224){ $self->{sha}=\&_sha256; $self->{H}=[@H0224] }
elsif($alg == 256){ $self->{sha}=\&_sha256; $self->{H}=[@H0256] }
elsif($alg == 384){ $self->{sha}=$sha512;   $self->{H}=[@H0384] }
elsif($alg == 512){ $self->{sha}=$sha512;   $self->{H}=[@H0512] }
push(@{$self->{H}}, 0) while scalar(@{$self->{H}}) < 8;
$self;
}

sub _shaopen{
my($alg)=@_;
my($self);
return unless grep { $alg == $_ } (1, 224, 256, 384, 512);
return if($alg >= 384 && !$uses64bit);
$self->{alg}=$alg;
_sharewind($self);
}

sub _shadirect{
my($bitstr, $bitcnt, $self)=@_;
my $savecnt=$bitcnt;
my $offset=0;
my $blockbytes=$self->{blocksize} >> 3;
while ($bitcnt >= $self->{blocksize}){
&{$self->{sha}}($self, substr($bitstr, $offset, $blockbytes));
$offset += $blockbytes;
$bitcnt -= $self->{blocksize};
}
if($bitcnt > 0){
$self->{block}=substr($bitstr, $offset, _BYTECNT($bitcnt));
$self->{blockcnt}=$bitcnt;
}
$savecnt;
}

sub _shabytes{
my($bitstr, $bitcnt, $self)=@_;
my($numbits);
my $savecnt=$bitcnt;
if($self->{blockcnt} + $bitcnt >= $self->{blocksize}){
$numbits=$self->{blocksize} - $self->{blockcnt};
$self->{block} .= substr($bitstr, 0, $numbits >> 3);
$bitcnt -= $numbits;
$bitstr=substr($bitstr, $numbits >> 3, _BYTECNT($bitcnt));
&{$self->{sha}}($self, $self->{block});
$self->{block}="";
$self->{blockcnt}=0;
_shadirect($bitstr, $bitcnt, $self);
}
else {
$self->{block} .= substr($bitstr, 0, _BYTECNT($bitcnt));
$self->{blockcnt} += $bitcnt;
}
$savecnt;
}

sub _shabits{
my($bitstr, $bitcnt, $self)=@_;
my($i, @buf);
my $numbytes=_BYTECNT($bitcnt);
my $savecnt=$bitcnt;
my $gap=8 - $self->{blockcnt} % 8;
my @c=unpack("C*", $self->{block});
my @b=unpack("C" . $numbytes, $bitstr);
$c[$self->{blockcnt}>>3] &= (~0 << $gap);
$c[$self->{blockcnt}>>3] |= $b[0] >> (8 - $gap);
$self->{block}=pack("C*", @c);
$self->{blockcnt} += ($bitcnt < $gap) ? $bitcnt : $gap;
return($savecnt) if $bitcnt < $gap;
if($self->{blockcnt} == $self->{blocksize}){
&{$self->{sha}}($self, $self->{block});
$self->{block}="";
$self->{blockcnt}=0;
}
return($savecnt) if($bitcnt -= $gap) == 0;
for ($i=0; $i < $numbytes - 1; $i++){
$buf[$i]=(($b[$i] << $gap) & 0xff) | ($b[$i+1] >> (8 - $gap));
}
$buf[$numbytes-1]=($b[$numbytes-1] << $gap) & 0xff;
_shabytes(pack("C*", @buf), $bitcnt, $self);
$savecnt;
}

sub _shawrite{
my($bitstr, $bitcnt, $self)=@_;
return(0) unless $bitcnt > 0;
no integer;
if(($self->{lenll} += $bitcnt) >= $TWO32){
$self->{lenll} -= $TWO32;
if(++$self->{lenlh} >= $TWO32){
$self->{lenlh} -= $TWO32;
if(++$self->{lenhl} >= $TWO32){
$self->{lenhl} -= $TWO32;
if(++$self->{lenhh} >= $TWO32){
$self->{lenhh} -= $TWO32;
}
}
}
}
use integer;
my $blockcnt=$self->{blockcnt};
return(_shadirect($bitstr, $bitcnt, $self)) if $blockcnt == 0;
return(_shabytes ($bitstr, $bitcnt, $self)) if $blockcnt % 8 == 0;
return(_shabits  ($bitstr, $bitcnt, $self));
}

sub _shafinish {
my($self)=@_;
my $LENPOS=$self->{alg} <= 256 ? 448 : 896;
_SETBIT($self, $self->{blockcnt}++);
while ($self->{blockcnt} > $LENPOS){
if($self->{blockcnt} < $self->{blocksize}){
_CLRBIT($self, $self->{blockcnt}++);
}
else {
&{$self->{sha}}($self, $self->{block});
$self->{block}="";
$self->{blockcnt}=0;
}
}
while ($self->{blockcnt} < $LENPOS){
_CLRBIT($self, $self->{blockcnt}++);
}
if($self->{blocksize} > 512){
$self->{block} .= pack("N", $self->{lenhh} & $MAX32);
$self->{block} .= pack("N", $self->{lenhl} & $MAX32);
}
$self->{block} .= pack("N", $self->{lenlh} & $MAX32);
$self->{block} .= pack("N", $self->{lenll} & $MAX32);
&{$self->{sha}}($self, $self->{block});
}

sub _shadigest{my($self)=@_; _digcpy($self); $self->{digest}}

sub _shahex{
my($self)=@_;
_digcpy($self);
join("", unpack("H*", $self->{digest}));
}

sub _shabase64{
my($self)=@_;
_digcpy($self);
my $b64=pack("u", $self->{digest});
$b64 =~ s/^.//mg;
$b64 =~ s/\n//g;
$b64 =~ tr|` -_|AA-Za-z0-9+/|;
my $numpads=(3 - length($self->{digest}) % 3) % 3;
$b64 =~ s/.{$numpads}$// if $numpads;
$b64;
}

sub _shadsize{my($self)=@_; $self->{digestlen} }

sub _shacpy{
my($to, $from)=@_;
$to->{alg}=$from->{alg};
$to->{sha}=$from->{sha};
$to->{H}=[@{$from->{H}}];
$to->{block}=$from->{block};
$to->{blockcnt}=$from->{blockcnt};
$to->{blocksize}=$from->{blocksize};
for (qw(lenhh lenhl lenlh lenll)){ $to->{$_}=$from->{$_} }
$to->{digestlen}=$from->{digestlen};
$to;
}

sub _shadup{my($self)=@_; my($copy); _shacpy($copy, $self)}

sub _shadump{
my $file=shift;
$file="-" if(!defined($file) || $file eq "");
my $fh=FileHandle->new($file, "w") or return;
my $self=shift;
my $is32bit=$self->{alg} <= 256;
my $fmt=$is32bit ? ":%08x" : ":%016x";
printf $fh "alg:%d\n", $self->{alg};
printf $fh "H";
for (@{$self->{H}}){ printf $fh $fmt, $is32bit ? $_ & $MAX32 : $_ }
printf $fh "\nblock";
my @c=unpack("C*", $self->{block});
push(@c, 0x00) while scalar(@c) < ($self->{blocksize} >> 3);
for (@c){ printf $fh ":%02x", $_ }
printf $fh "\nblockcnt:%u\n", $self->{blockcnt};
printf $fh "lenhh:%lu\n", $self->{lenhh} & $MAX32;
printf $fh "lenhl:%lu\n", $self->{lenhl} & $MAX32;
printf $fh "lenlh:%lu\n", $self->{lenlh} & $MAX32;
printf $fh "lenll:%lu\n", $self->{lenll} & $MAX32;
close($fh);
$self;
}

sub _match{
my($fh, $tag)=@_;
my @f;
while (<$fh>){
s/^\s+//;
s/\s+$//;
next if(/^(#|$)/);
@f=split(/[:\s]+/);
last;
}
shift(@f) eq $tag or return;
return(@f);
}

sub _shaload{
my $file=shift;
$file="-" if(!defined($file) || $file eq "");
my $fh=FileHandle->new($file, "r") or return;
my @f=_match($fh, "alg") or return;
my $self=_shaopen(shift(@f)) or return;
@f=_match($fh, "H") or return;
my $numxdigits=$self->{alg} <= 256 ? 8 : 16;
for (@f){ $_="0" . $_ while length($_) < $numxdigits }
for (@f){ $_=substr($_, 1) while length($_) > $numxdigits }
@{$self->{H}}=map { $self->{alg} <= 256 ? hex($_) :
((hex(substr($_, 0, 8)) << 16) << 16) |
hex(substr($_, 8))} @f;
@f=_match($fh, "block") or return;
for (@f){ $self->{block} .= chr(hex($_))}
@f=_match($fh, "blockcnt") or return;
$self->{blockcnt}=shift(@f);
$self->{block}=substr($self->{block},0,_BYTECNT($self->{blockcnt}));
@f=_match($fh, "lenhh") or return;
$self->{lenhh}=shift(@f);
@f=_match($fh, "lenhl") or return;
$self->{lenhl}=shift(@f);
@f=_match($fh, "lenlh") or return;
$self->{lenlh}=shift(@f);
@f=_match($fh, "lenll") or return;
$self->{lenll}=shift(@f);
close($fh);
$self;
}

sub _hmacopen{
my($alg, $key)=@_;
my($self);
$self->{isha}=_shaopen($alg) or return;
$self->{osha}=_shaopen($alg) or return;
if(length($key) > $self->{osha}->{blocksize} >> 3){
$self->{ksha}=_shaopen($alg) or return;
_shawrite($key, length($key) << 3, $self->{ksha});
_shafinish($self->{ksha});
$key=_shadigest($self->{ksha});
}
$key .= chr(0x00)
while length($key) < $self->{osha}->{blocksize} >> 3;
my @k=unpack("C*", $key);
for (@k){ $_ ^= 0x5c }
_shawrite(pack("C*", @k), $self->{osha}->{blocksize}, $self->{osha});
for (@k){ $_ ^= (0x5c ^ 0x36)}
_shawrite(pack("C*", @k), $self->{isha}->{blocksize}, $self->{isha});
$self;
}

sub _hmacwrite{
my($bitstr, $bitcnt, $self)=@_;
_shawrite($bitstr, $bitcnt, $self->{isha});
}

sub _hmacfinish{
my($self)=@_;
_shafinish($self->{isha});
_shawrite(_shadigest($self->{isha}),
$self->{isha}->{digestlen} << 3, $self->{osha});
_shafinish($self->{osha});
}

sub _hmacdigest{my($self)=@_; _shadigest($self->{osha})}
sub _hmachex{my($self)=@_; _shahex($self->{osha})    }
sub _hmacbase64{my($self)=@_; _shabase64($self->{osha})}

# SHA and HMAC-SHA functions

my @suffix_extern=("", "_hex", "_base64");
my @suffix_intern=("digest", "hex", "base64");

my($i, $alg);
for $alg (1, 224, 256, 384, 512){
for $i (0 .. 2){
my $fcn='sub sha' . $alg . $suffix_extern[$i] . ' {
my $state=_shaopen(' . $alg . ') or return;
for (@_){ _shawrite($_, length($_) << 3, $state)}
_shafinish($state);
_sha' . $suffix_intern[$i] . '($state);
}';
eval($fcn);
push(@EXPORT_OK, 'sha' . $alg . $suffix_extern[$i]);
$fcn='sub hmac_sha' . $alg . $suffix_extern[$i] . ' {
my $state=_hmacopen(' . $alg . ', pop(@_)) or return;
for (@_){ _hmacwrite($_, length($_) << 3, $state)}
_hmacfinish($state);
_hmac' . $suffix_intern[$i] . '($state);
}';
eval($fcn);
push(@EXPORT_OK, 'hmac_sha' . $alg . $suffix_extern[$i]);
}}

sub hashsize{my $self=shift; _shadsize($self) << 3 }
sub algorithm{my $self=shift; $self->{alg} }

sub add{
my $self=shift;
for (@_){_shawrite($_, length($_) << 3, $self)}
$self;
}

sub digest{
my $self=shift;
_shafinish($self);
my $rsp=_shadigest($self);
_sharewind($self);
$rsp;
}

sub _Hexdigest{
my $self=shift;
_shafinish($self);
my $rsp=_shahex($self);
_sharewind($self);
$rsp;
}

sub _B64digest{
my $self=shift;
_shafinish($self);
my $rsp=_shabase64($self);
_sharewind($self);
$rsp;
}

sub new{
my($class, $alg)=@_;
$alg =~ s/\D+//g if defined $alg;
if(ref($class)){
unless (defined($alg) && ($alg != $class->algorithm)){
_sharewind($class);
return($class);
}
my $self=_shaopen($alg) or return;
return(_shacpy($class, $self));
}
$alg=1 unless defined $alg;
my $self=_shaopen($alg) or return;
bless($self, $class);
$self;
}

sub clone{
my $self=shift;
my $copy=_shadup($self) or return;
bless($copy, ref($self));
return($copy);
}
*reset=\&new;

sub add_bits{
my($self, $data, $nbits)=@_;
unless (defined $nbits){
$nbits=length($data);
$data=pack("B*", $data);
}
_shawrite($data, $nbits, $self);
return($self);
}

sub _bail{
my $msg=shift;
require Carp;
Carp::croak("$msg: $!");
}

sub _addfile{
my ($self, $handle)=@_;
my $n;
my $buf="";
while (($n=read($handle, $buf, 4096))){
$self->add($buf);
}
_bail("Read failed") unless defined $n;
$self;
}

sub _Addfile{
my ($self, $file, $mode)=@_;
return(_addfile($self, $file)) unless ref(\$file) eq 'SCALAR';
$mode=defined($mode) ? $mode : "";
my ($binary, $portable)=map { $_ eq $mode } ("b", "p");
my $text=-T $file;
local *FH;
$file =~ s#^(\s)#./$1#;
open(FH, "< $file\0") or _bail("Open failed");
binmode(FH) if $binary || $portable;
unless ($portable && $text){
$self->_addfile(*FH);
close(FH);
return($self);
}
my ($n1, $n2);
my ($buf1, $buf2)=("", "");
while (($n1=read(FH, $buf1, 4096))){
while (substr($buf1, -1) eq "\015"){
$n2=read(FH, $buf2, 4096);
_bail("Read failed") unless defined $n2;
last unless $n2;
$buf1 .= $buf2;
}
$buf1 =~ s/\015?\015\012/\012/g;
$buf1 =~ s/\015/\012/g;
$self->add($buf1);
}
_bail("Read failed") unless defined $n1;
close(FH);
$self;
}

sub dump{
my $self=shift;
my $file=shift || "";
_shadump($file, $self) or return;
return($self);
}

sub load{
my $class=shift;
my $file=shift || "";
if(ref($class)){
my $self=_shaload($file) or return;
return(_shacpy($class, $self));
}
my $self=_shaload($file) or return;
bless($self, $class);
return($self);
}

1;

