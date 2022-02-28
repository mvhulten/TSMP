#! /bin/ksh

always_pfl(){
route "${cblue}>> always_pfl${cnormal}"
route "${cblue}<< always_pfl${cnormal}"
}

configure_pfl(){
route "${cblue}>> configure_pfl${cnormal}"
    export PARFLOW_INS="$pfldir/bin"
    export PARFLOW_BLD="$pfldir/build"
#    export PFV="oas-gpu"
    export RMM_ROOT=$pfldir/rmm
#
    C_FLAGS="-fopenmp -Wall -Werror"
    flagsSim="  -DMPIEXEC_EXECUTABLE=$(which srun)"
    flagsSim+=" -DPARFLOW_AMPS_LAYER=oas3"
    flagsSim+=" -DOAS3_ROOT=$oasdir/$platform"
    flagsSim+=" -DSILO_ROOT=$EBROOTSILO"
    flagsSim+=" -DHYPRE_ROOT=$EBROOTHYPRE"
    flagsSim+=" -DCMAKE_C_FLAGS=$C_FLAGS"
    flagsSim+=" -DCMAKE_BUILD_TYPE=Release"
    flagsSim+=" -DPARFLOW_ENABLE_TIMING=TRUE"
    flagsSim+=" -DCMAKE_INSTALL_PREFIX=$PARFLOW_INS"
    flagsSim+=" -DNETCDF_DIR=$ncdfPath"
    flagsSim+=" -DNETCDF_Fortran_ROOT=$ncdfPath"
    flagsSim+=" -DTCL_TCLSH=$tclPath/bin/tclsh8.6"
    flagsSim+=" -DPARFLOW_AMPS_SEQUENTIAL_IO=on"
    flagsSim+=" -DPARFLOW_ENABLE_SLURM=TRUE"
#
    pcc="$mpiPath/bin/mpicc"
    pfc="$mpiPath/bin/mpif90"
    pf77="$mpiPath/bin/mpif77"
    pcxx="$mpiPath/bin/mpic++"
#
    comment "    add parflow3_9 paths $PARFLOW_INS, $PARFLOW_BLD "
     mkdir -p $PARFLOW_INS
     mkdir -p $PARFLOW_BLD
    check

    comment " parflow is configured for $processor "
    check
    if [[ $processor == "GPU" ]]; then
       cd $pfldir
       comment "module load CUDA  mpi-settings/CUDA "
        module load CUDA  mpi-settings/CUDA >> $log_file 2>> $err_file
       check
       comment "    additional configuration options for GPU are set "
        flagsSim+=" -DPARFLOW_ACCELERATOR_BACKEND=cuda"
        flagsSim+=" -DRMM_ROOT=$RMM_ROOT"
        flagsSim+=" -DCMAKE_CUDA_RUNTIME_LIBRARY=Shared"
       check
       comment "    git clone  RAPIDS Memory Manager "
       if [ -d $RMM_ROOT ] ; then 
        comment "  remove $RMM_ROOT "
        rm -rf $RMM_ROOT >> $log_file 2>> $err_file
        check
       fi
       git clone -b branch-0.10 --single-branch --recurse-submodules https://github.com/hokkanen/rmm.git >> $log_file 2>> $err_file
       check
        mkdir -p $RMM_ROOT/build
        cd $RMM_ROOT/build
       comment "    configure RMM: RAPIDS Memory Manager "
        cmake ../ -DCMAKE_INSTALL_PREFIX=$RMM_ROOT >> $log_file 2>> $err_file
       check
       comment "    make RMM "
        make -j  >> $log_file 2>> $err_file
       check
       comment "    make install RMM "
        make install >> $log_file 2>> $err_file
       check
    fi

    c_configure_pfl

route "${cblue}<< configure_pfl${cnormal}"
}

make_pfl(){
route "${cblue}>> make_pfl${cnormal}"
  c_make_pfl
route "${cblue}<< make_pfl${cnormal}"
}


substitutions_pfl(){
route "${cblue}>> substitutions_pfl${cnormal}"

route "${cblue}<< substitutions_pfl${cnormal}"
}


setup_pfl(){
route "${cblue}>> setup_pfl${cnormal}"
  c_setup_pfl

route "${cblue}<< setup_pfl${cnormal}"
}

