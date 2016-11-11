#!/bin/ksh
#ParFlow DART JOB SUBMISSION

USAGE="sbatch <scriptname>"
# JUROPATEST module load intel-para/2014.11
# all in same directory, copy beforehand manually to /work/hbn33/hbn331
 
#SBATCH --job-name="TerrSysMP"
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=48
#SBATCH --output=mpiMPMD-out.%j
#SBATCH --error=mpiMPMD-err.%j
#SBATCH --time=01:00:00
#SBATCH --partition=batch
#SBATCH --mail-type=ALL
 
export LOGNAME="$WORK/rundart01"
export DART_DIR="$HOME/DART/lanai/models/terrsysmp/parflow/work"
export LD_LIBRARY_PATH="$EBROOTNETCDFMINFORTRAN/lib/":$LD_LIBRARY_PATH
cd $LOGNAME
source $LOGNNAME/loadenvs

# Cleanup---------------
rm input.nml
rm pfidb_dz
rm filter_ics.*
rm P*Diag.nc
rm filter_res*
rm dart_log.*
rm obs_seq.*
rm log_file
rm err_file
rm ready.txt
rm pfl_press.pfb 
rm pfl_satur.pfb
rm pflgrid.nc
rm clm_restart.nc
rm parflow_restart.pfb

# Copy namelist and executable to rundirectory--------#TODO-
cp $DART_DIR/input.nml .
cp $DART_DIR/pfidb_dz .
cp $DART_DIR/filter .
cp $DART_DIR/dart_to_parflow .
cp $DART_DIR/parflow_to_dart .

numInst=48

for instance in {0..$(($numInst-1))}
do
  cd tsmp_instance_$instance

  rm input.nml
  rm pfidb_dz
  rm dart_log.*
  rm dart_posterior
  rm pfl_press.pfb
  rm pfl_satur.pfb
  rm pflgrid.nc
  rm clm_restart.nc
  rm parflow_restart.pfb
  rm parflow_prior_time.txt 
  rm dart_posterior_times.txt

  ln -s ../input.nml .
  prspfb=`ls -1 rurlaf.out.press*.pfb | tail -n -1` 
  satpfb=`ls -1 rurlaf.out.satur*.pfb | tail -n -1`
  clmrst=`ls -1 clmoas.clm2.r.*.nc | tail -n -2 | head -n 1`
  pflgrd=`ls grids.nc`
  ln -s ../pfidb_dz .
  ln -s $prspfb pfl_press.pfb 
  ln -s $satpfb pfl_satur.pfb
  ln -s $pflgrd pflgrid.nc
  ln -s $clmrst clm_restart.nc
  ../parflow_to_dart || exit 1

  dartinstance=$(( $instance + 1 ))
  filterName=`printf ../filter_ics.%04d $dartinstance`
  mv dart_prior $filterName 
  cd ..
done

wait

# GRAB PARFLOW TIME FOR ASSIMILATION
timefile_path="tsmp_instance_0"
dIndat=`grep defaultInitDate $timefile_path/parflow_prior_time.txt | cut -d' ' -f2`

ln -s $DART_DIR/obs_seq.$dIndat obs_seq.out || exit 2

#for filter?
ln -s tsmp_instance_0/$prspfb pfl_press.pfb 
ln -s tsmp_instance_0/$satpfb pfl_satur.pfb
ln -s tsmp_instance_0/$pflgrd pflgrid.nc
ln -s tsmp_instance_0/$clmrst clm_restart.nc
echo "CPS 2"
#for filter?

date
srun  -n 48  ./filter || exit 3  >> log_file 2>> err_file
date

for instance in {0..$(($numInst-1))}
do
  cd tsmp_instance_$instance
  dartinstance=$(( $instance + 1 ))
  filterRestartName=`printf ../filter_restart.%04d $dartinstance`
  ln -s $filterRestartName dart_posterior 
  ../dart_to_parflow || exit 4
  cd ..
done

wait

echo "ready" > ready.txt
exit 0
