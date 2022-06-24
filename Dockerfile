FROM ubuntu:22.04


RUN apt-get update
RUN apt-get install -y build-essential



RUN apt-get install -y build-essential libblas-dev liblapack-dev gfortran libglew-dev \
										freeglut3 \ 		
										freeglut3-dev \
										libboost-all-dev  \
										scons \
										libpng-dev liblapacke-dev \
										libglfw3-dev \
										libatlas-base-dev \ 
										wget make \
										exuberant-ctags \
										-qqy x11-apps


COPY arcsim-0.3.1 ./arcsim
COPY SConstruct ./arcsim/dependencies/jsoncpp/

RUN cd ./arcsim \
    && rm -rf dependencies/taucs/build/darwin \
    && sed -i 's/<< file/<< std::endl/' src/sparse.hpp \
    && sed -i 's/T clamp/T my_clamp/' src/util.hpp \
    && find src/ -type f -exec sed -i 's/clamp(/my_clamp(/' {} \; \
    && rm Makefile \
    && ln -s Makefile.linux Makefile 

RUN make -C ./arcsim/dependencies
RUN make -C ./arcsim/
