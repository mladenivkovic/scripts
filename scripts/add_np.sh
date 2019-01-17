#=============================================
# Replace commonly used left out numpy imports
# in all files in this directory
#=============================================

sed -i 's/from numpy import \*/import numpy as np/g' *.py
sed -i 's/import numpy as np\*/import numpy as np/g' *.py

sed -i 's/xrange/range/g' *.py

sed -i 's/float32/np.float32/g' *.py
sed -i 's/int32/np.int32/g' *.py

sed -i 's/array(/np.array(/g' *.py
sed -i 's/ones/np.ones/g' *.py
sed -i 's/zeros/np.zeros/g' *.py
sed -i 's/arange/np.arange/g' *.py
sed -i 's/linspace/np.linspace/g' *.py

sed -i 's/where/np.where/g' *.py
sed -i 's/clip/np.clip/g' *.py
sed -i 's/concatenate/np.concatenate/g' *.py
sed -i 's/transpose/np.transpose/g' *.py
sed -i 's/ravel/np.ravel/g' *.py
sed -i 's/isreal(/np.isreal(/g' *.py
sed -i 's/compress(/np.compress(/g' *.py

sed -i 's/log(/np.log(/g' *.py
sed -i 's/log10(/np.log10(/g' *.py
sed -i 's/exp(/np.exp(/g' *.py
sed -i 's/sqrt(/np.sqrt(/g' *.py
sed -i 's/sin(/np.sin(/g' *.py
sed -i 's/cos(/np.cos(/g' *.py
sed -i 's/ pi / np.pi /g' *.py


# in case something went wrong
sed -i 's/lognp.log/loglog/g' *.py
sed -i 's/mpi_np.arange/mpi_arange/g' *.py
sed -i 's/np.np./np./g' *.py
sed -i 's/np.np.np./np./g' *.py

