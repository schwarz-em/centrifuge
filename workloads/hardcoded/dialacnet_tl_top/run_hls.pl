#!/usr/bin/perl
use warnings;
use strict;
use Cwd;
use File::Copy;

my $file_name = $ARGV[0];
my $func_name = $ARGV[1];

my $prefix = undef;

my $num_args = $#ARGV + 1;
if ($num_args > 2) {
  $prefix = $ARGV[2];
}

#############################GENERATE HLS##############################

# Generate directive file based on LLVM emitted output
# If the variable is of pointer type that an ap_bus interface is generated  

my $directive_tcl_insn = 'set_directive_interface -mode ap_bus "test_c_func" test_var
';

my $prefix_tcl = "";
if ($prefix) {
  $prefix_tcl = "config_rtl -prefix ".$prefix."\n";
}
my $hls_pgm = undef;
if (-f $file_name.".cpp"){
  $hls_pgm = $file_name.'.cpp -cflags "-std=c++0x" ';
} else {
  $hls_pgm = $file_name.".c";
}

# should change to add all .c files 
my $hls_tcl = 'open_project -reset test_c_prj
set_top test_c_func
add_files hls_pgm 
open_solution -reset "solution1"
set_part {xcvu9p-flgb2104-2-i}
config_compile -ignore_long_run_time
create_clock -period 10 -name default
'.$prefix_tcl.'
#source "./test_c_prj/solution1/directives.tcl"
#config_interface -clock_enable
config_interface -m_axi_addr64
csynth_design
#export_design -format ip_catalog
exit';

my $dir = getcwd;
open HLS, ">$dir/run_hls.tcl";

# replace the function name and file name
$hls_tcl =~ s/test_c_func/$func_name/g;
$hls_tcl =~ s/test_c/$file_name/g;
$hls_tcl =~ s/hls_pgm/$hls_pgm/g;


# run vivado hls
print HLS $hls_tcl;
system("vivado_hls -f run_hls.tcl");

my $vivado_dir = "$dir/$file_name"."_prj/solution1/syn/verilog/";
my $verilog_dir = "$dir/../verilog/";

mkdir $verilog_dir unless (-d $verilog_dir);
unlink glob "$verilog_dir/*";

opendir(DIR, $vivado_dir) or die "Can't opendir $vivado_dir: $! \n";
 
my @files=readdir(DIR);
closedir(DIR);

foreach my $v_file (@files){
	# Open and replace one line 

        chdir($vivado_dir);
	my $vivado_dir_escape = $vivado_dir;
	$vivado_dir_escape =~ s/\//\\\//g;
	my $perl_cmd = "perl -p -i -e 's/\$readmemh\\\(\\\"\\\.\/\$readmemh(\\\"$vivado_dir_escape/g' *";
	 
	print $perl_cmd;
	system ($perl_cmd);

	$perl_cmd = "perl -p -i -e \"s/'bx/1'b0/g\" *";
	system ($perl_cmd);
  print $perl_cmd;

	chdir($dir);

	print "$v_file\n";
    	if (-f "$vivado_dir/$v_file") {  
		copy("$vivado_dir/$v_file", $verilog_dir) or die "File cannot be copied! $v_file $verilog_dir\n";
	}
}

#die $!;

