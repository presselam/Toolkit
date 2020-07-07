for dir in Profiler PSInfo Progress StructurePrinter Utilities Toolkit tools;
do 
	pushd ${dir}
	perl Makefile.PL PREFIX="$HOME" LIB="${HOME}/lib" INST_SCRIPT="$HOME/bin"
	make install
	popd
done
