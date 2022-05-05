#!/bin/csh
#PBS -S /bin/csh
#PBS -N 12LUV_6Fab_
#PBS -l nodes=1:ppn=6 
#PBS -o 12LUV_6Fab.out
#PBS -e 12LUV_6Fab.err




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


gmx grompp -f steep.mdp -o steep.tpr -c 12LUV_6Fab.gro -p 12LUV_6Fab.top -maxwarn 1
gmx mdrun -pin on -v -deffnm steep >& steep.out

# Minimization
set cntm    = 1
set cntmax =  5

while ( ${cntm} <= ${cntmax} )
    @ pcnt = ${cntm} - 1
    if ( ${cntm} == 1 ) then
		gmx grompp -f bd_em_step_{$cntm}.mdp -o en_min_{$cntm}.tpr -c steep.gro -p 12LUV_6Fab.top -maxwarn -1
        gmx mdrun -pin on -v -deffnm en_min_{$cntm} >& en_min_{$cntm}.out
    else
 		gmx grompp -f bd_em_step_{$cntm}.mdp -o en_min_{$cntm}.tpr -c en_min_{$pcnt}.gro -p 12LUV_6Fab.top -maxwarn -1
        gmx mdrun  -pin on -v -deffnm en_min_{$cntm} >& en_min_{$cntm}.out
    endif
    @ cntm += 1

end

echo ">>>>>>>End Equilibration: `date`"

# Production
set cntp    = 1
set cntmaxp = 1
while ( ${cntp} <= ${cntmaxp} )
    @ pcntp = ${cntp} - 1
    if ( ${cntp} == 1 ) then
 		gmx grompp -f bd_prod.mdp -o 12LUV_6Fab_{$cntp}.tpr -c en_min_{$cntmax}.gro -n index.ndx -p 12LUV_6Fab.top -maxwarn -1
        gmx mdrun  -pin on -v -deffnm 12LUV_6Fab_{$cntp} >& 12LUV_6Fab_{$cntp}.out
    else
  		gmx grompp -f bd_prod.mdp -o 12LUV_6Fab_{$cntp}.tpr -c 12LUV_6Fab_{$pcntp}.gro -n index.ndx -p 12LUV_6Fab.top -maxwarn -1
        gmx mdrun -pin on -v -deffnm 12LUV_6Fab_{$cntp} >& 12LUV_6Fab_{$cntp}.out	
    endif
    @ cntp += 1
end

mkdir equi
mkdir prod
mkdir msd

mv en_min_* equi/
mv *.trr *.tpr msd/
mv 12LUV_6Fab_* prod/

echo ">>>>>>>End Production: `date`"


exit
#EOF

