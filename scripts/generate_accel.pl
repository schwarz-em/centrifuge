#!/usr/bin/perl
use warnings;
use strict;
use Cwd;
use File::Copy;

my $rdir = $ENV{'RDIR'};
print $rdir;
if ((not defined($rdir)) or $rdir eq '') {
    print("Please source sourceme-f1-manager.sh!\n");
    exit();
}

sub generate_accel{

    my @accel_tuples= @{$_[0]};
  
    foreach my $accel_tuple_ref (@accel_tuples) {
      print($accel_tuple_ref);
      my @accel_tuple = @{$accel_tuple_ref};

      my $pgm = $accel_tuple[0];
      my $func = $accel_tuple[1];
      my $bm_path = $accel_tuple[2];
      my $bm_path_c = $bm_path.'/src/main/c/';

      my $is_rocc = $accel_tuple[3];
      my $idx_addr = $accel_tuple[4];

      my $prefix=" ";

      my $num_args = scalar @accel_tuple;
      if ($num_args > 5) {
        $prefix = $accel_tuple[5];
      }
     
      print("Pgm: ".$pgm."\n");
      print("Func: ".$func."\n");
      print("Path: ".$bm_path."\n");
      print("Is RoCC not TL?: ".$is_rocc."\n");
      print("RoCC Idx or TL Addr: ".$idx_addr."\n");
      print("Prefix: ".$prefix."\n");
      $ENV{'PGM'} = $pgm;
      $ENV{'FUNC'} = $func;
      my $PGM = $pgm;
      my $FUNC = $func;
      my $RDIR = $rdir;

      system("mkdir -p $bm_path/src/main/c");
      chdir("$bm_path/src/main/c/") or die $!;
      system("cp $RDIR/tools/centrifuge/examples/${PGM}/* $bm_path_c");
      system("cp $RDIR/tools/centrifuge/scripts/run_hls.pl $bm_path_c");
      #system("cp $RDIR/hls/sw/time.h $bm_path/src/main/c/");
      #system("cp $RDIR/hls/sw/rocc.h $bm_path/src/main/c/");

      # Specialize the Makefile for this function
      system("sed -i 's/^FUNC=.*/FUNC=$func/g' $bm_path_c/Makefile");
      
      my $dir = getcwd;
      print("$dir\n");
      #next;

      system("perl run_hls.pl ${PGM} ${FUNC} $prefix"); 

      if ($is_rocc) {
          system("cp $RDIR/tools/centrifuge/scripts/run_chisel.pl $bm_path_c");
          system("cp $RDIR/tools/centrifuge/scripts/generate_wrapper.pl $bm_path_c");
          system("perl run_chisel.pl ${PGM} ${FUNC} $prefix");
          system("perl generate_wrapper.pl ${PGM} ${FUNC} $idx_addr $prefix");
          #system("make clean");
          #system("make CUSTOM_INST=1");
      } else {
          system("cp $RDIR/tools/centrifuge/scripts/run_chisel_tl.pl $bm_path_c");
          system("cp $RDIR/tools/centrifuge/scripts/generate_wrapper_tl.pl $bm_path_c");
          system("perl run_chisel_tl.pl ${PGM} ${FUNC} $idx_addr $prefix");
          system("perl generate_wrapper_tl.pl ${PGM} ${FUNC} $idx_addr $prefix");
          #system("make clean");
          #system("make CUSTOM_DRIVER=1");
      }
   }
}

# Example with RoCC and TL accel
#my @input = (["vadd", "vadd", "$rdir/sim/target-rtl/firechip/hls_vadd_vadd/src/main/c", 1, "0", "rocc0_"], ["vadd_tl", "vadd", "$rdir/sim/target-rtl/firechip/hls_vadd_tl_vadd/src/main/c", 0, "0x20000", "tl0_"]);
#generate_accel(\@input);
1;
