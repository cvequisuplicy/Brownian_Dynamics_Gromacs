#!/bin/csh
#PBS -S /bin/csh
#PBS -N 1500LUV_750Fab_
#PBS -l nodes=1:ppn=6 
#PBS -o 1500LUV_750Fab.out
#PBS -e 1500LUV_750Fab.err




date

echo ">>>>>>>Start:`date`"

setenv OMP_NUM_THREADS 12

setenv MPI_MCA_mca_component_show_load_errors 0

setenv PMIX_MCA_mca_component_show_load_errors 0



### cd to directory where the job was submitted:
cd $PBS_O_WORKDIR

echo "----------------"
echo "PBS job running on: `hostname`"
echo "in directory:       `pwd`"
echo "nodefile:"
cat $PBS_NODEFILE
echo "----------------"

echo ">>>>>>>Start: `date`"


source /opt/ohpc/pub/gromacs/bin/GMXRC

gmx genconf -f 12LUV_6Fab_1.gro -nbox 5 5 5 -o 1500LUV_750Fab.gro 


gmx grompp -f steep.mdp -o steep.tpr -c 1500LUV_750Fab.gro -p 1500LUV_750Fab.top -maxwarn 1
gmx mdrun -pin on -v -deffnm steep >& steep.out


# Minimization
set cntm    = 1
set cntmax =  5

while ( ${cntm} <= ${cntmax} )
    @ pcnt = ${cntm} - 1
    if ( ${cntm} == 1 ) then
		gmx grompp -f bd_em_step_{$cntm}.mdp -o en_min_{$cntm}.tpr -c steep.gro -p 1500LUV_750Fab.top -maxwarn -1
        gmx mdrun -pin on -v -deffnm en_min_{$cntm} >& en_min_{$cntm}.out
    else
 		gmx grompp -f bd_em_step_{$cntm}.mdp -o en_min_{$cntm}.tpr -c en_min_{$pcnt}.gro -p 1500LUV_750Fab.top -maxwarn -1
        gmx mdrun  -pin on -v -deffnm en_min_{$cntm} >& en_min_{$cntm}.out
    endif
    @ cntm += 1

end

echo ">>>>>>>End Equilibration: `date`"

echo q | gmx make_ndx -f en_min_{$cntmax}.gro

# Production
set cntp    = 1
set cntmaxp = 10
while ( ${cntp} <= ${cntmaxp} )
    @ pcntp = ${cntp} - 1
    if ( ${cntp} == 1 ) then
 		gmx grompp -f bd_prod.mdp -o 1500LUV_750Fab_{$cntp}.tpr -c en_min_{$cntmax}.gro -n index.ndx -p 1500LUV_750Fab.top -maxwarn -1
        gmx mdrun  -pin on -v -deffnm 1500LUV_750Fab_{$cntp} >& 1500LUV_750Fab_{$cntp}.out
    else
  		gmx grompp -f bd_prod.mdp -o 1500LUV_750Fab_{$cntp}.tpr -c 1500LUV_750Fab_{$pcntp}.gro -n index.ndx -p 1500LUV_750Fab.top -maxwarn -1
        gmx mdrun -pin on -v -deffnm 1500LUV_750Fab_{$cntp} >& 1500LUV_750Fab_{$cntp}.out	
    endif
    @ cntp += 1
end

mkdir equi
mkdir prod
mkdir msd

mv en_min_* equi/
mv *.trr *.tpr msd/
mv 1500LUV_750Fab_* prod/

echo ">>>>>>>End Production: `date`"


exit
#EOF

