#=============================================
# Replace commonly used left out numpy imports
#
#   usage: 
#       add_np.sh <optional: filename(s)>
#       
#       if filenames are given, it will do it
#       for specified files. Otherwise, it'll
#       work for all *.py files.
#=============================================


if [[ $# > 0 ]]; then
    # if cmd line arg passed
    FILES="$@"
    echo "working for files: $FILES"
else
    FILES=`ls *.py`
    echo "working for *.py files"
fi

# extra: replace ''' with """
sed -i "s/'''/\"\"\"/g" $FILES


sed -i 's/from numpy import \*/import numpy as np/g' $FILES
sed -i 's/import numpy as np\*/import numpy as np/g' $FILES

sed -i 's/xrange/range/g' $FILES

sed -i 's/float64/np.float64/g' $FILES
sed -i 's/float32/np.float32/g' $FILES
sed -i 's/int32/np.int32/g' $FILES
sed -i 's/int16/np.int16/g' $FILES

sed -i 's/array(/np.array(/g' $FILES
sed -i 's/ones/np.ones/g' $FILES
sed -i 's/zeros/np.zeros/g' $FILES
sed -i 's/arange/np.arange/g' $FILES
sed -i 's/linspace/np.linspace/g' $FILES

sed -i 's/where/np.where/g' $FILES
sed -i 's/clip/np.clip/g' $FILES
sed -i 's/concatenate/np.concatenate/g' $FILES
sed -i 's/transpose/np.transpose/g' $FILES
sed -i 's/ravel/np.ravel/g' $FILES
sed -i 's/isreal(/np.isreal(/g' $FILES
sed -i 's/compress(/np.compress(/g' $FILES
sed -i 's/take(/np.take(/g' $FILES
sed -i 's/indices(/np.indices(/g' $FILES
sed -i 's/fromstring(/np.fromstring(/g' $FILES
sed -i 's/argmax(/np.argmax(/g' $FILES
sed -i 's/add.accumulate(/np.add.accumulate(/g' $FILES
sed -i 's/random.random(/np.random.random(/g' $FILES

sed -i 's/log(/np.log(/g' $FILES
sed -i 's/log10(/np.log10(/g' $FILES
sed -i 's/exp(/np.exp(/g' $FILES
sed -i 's/sqrt(/np.sqrt(/g' $FILES
sed -i 's/sin(/np.sin(/g' $FILES
sed -i 's/sinh(/np.sinh(/g' $FILES
sed -i 's/cos(/np.cos(/g' $FILES
sed -i 's/cosh(/np.cosh(/g' $FILES
sed -i 's/fmod(/np.fmod(/g' $FILES
sed -i 's/ pi / np.pi /g' $FILES
sed -i 's/ pi,/ np.pi,/g' $FILES
sed -i 's/,pi,/,np.pi,/g' $FILES



# in case something went wrong
sed -i 's/lognp.log/loglog/g' $FILES
sed -i 's/mpi_np.arange/mpi_arange/g' $FILES
sed -i 's/np\.np\.np\./np./g' $FILES
sed -i 's/np\.np\./np./g' $FILES
sed -i 's/\.np\././g' $FILES

