# arcsim-docker

This repo contains a Dockerfile and installation instructions for ARCSim 0.3.1 on Ubuntu 22.04

## Docker image

You can build a docker image from the Dockerfile yourself following instructions below or you can pull the full image from dockerhub:
```bash
docker pull ladekabovino/arcsim-ubuntu
```

## Installation and usage
ARCSim requires some tweaks to be installed properly on Ubuntu. These tweaks are already included to the Dockerfile, so you may not worry about them. 
Though I describe errors and workarounds I used further in this README.

You can also use these workarounds (see Dockerfile:L24) to install ARCSim to your OS without docker, though they were only tested for Ubuntu 22.04 and 21.10.

1. Clone this repository
```bash
git clone arcsim-docker
cd arcsim-docker
```

2. Download ARCSim 0.3.1 from the official webpage und unpack it to this repository's directory. 
Its contents should look like this:
```
arcsim-docker/
├── Dockerfile
├── README.md
├── SConstruct
├── arcsim-0.3.1
│   ├── INSTALL
│   ├── LICENSE
│   ├── Makefile -> Makefile.mac
│   ├── ...
```

3. Build docker
```bash
sudo docker build -t arcsim-ubuntu .
```

4. Add docker to xhost to pass your screen inside the container
```bash
xhost +"local:docker@"
```

5. Run the container

You can either run in interactively with `run_interactive.sh` or run a particular command with `run.sh` for example 
```bash
sudo bash run.sh bin/arcsim simulate conf/sphere.json
```


## Errors and workarounds for ARCSim installation on Ubuntu
You don't need this section if you followed installation instructions above.

Though I decided to describe the errors during ARCSim installation process on Ubuntu and ways to fix them for the sake of completeness.

These instructions were tested for Ubuntu 22.04 and 21.10. For more complete list of workarounds for other Ubuntu versions and earlier ARCSim versions you can refer to this repo.

### 1. scons and python3 problem
`scons` package for modern Ubuntu versions goes with `python3`, so we need to change several lines in `SConstruct` to make it work with `python3

Error message:
```
  File "/arcsim/dependencies/jsoncpp/SConstruct", line 31

    print "Using platform '%s'" %platform

    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

SyntaxError: Missing parentheses in call to 'print'. Did you mean print(...)?

```


Solution:
```bash
mv Sconstruct arcsim-0.3.1/dependencies/jsoncpp/SConstruct
```
### 2. prebuilt darwin version of taucs

When running `make` for ARCSim dependencies, it builds taucs version for linux, but then in `arcsim-0.3.1/dependencies/Makefile:L20` tries to copy build files from ALL builds there are which leads to an error.
So we need to remove pre-built files in order not to confuse the make script.

Error message:
```
cp: will not overwrite just-created 'include/taucs_config_build.h' with 'taucs/build/linux/taucs_config_build.h'
```

Solution:
```bash
rm -rf arcsim-0.3.1/dependencies/taucs/build/darwin
```

### 3. `operator<<` problem in `src/sparse.hpp`

We need to replace L118 line in `arcsim-0.3.1/src/sparce.hpp`

Error message:
```
In file included from src/optimization.hpp:30,
                 from src/auglag.cpp:27:
src/sparse.hpp: In function 'void debug_save_spmat(const SpMat<double>&)':
src/sparse.hpp:118:18: error: no match for 'operator<<' (operand types are 'std::basic_ostream<char>' and 
'std::fstream' {aka 'std::basic_fstream<char>'})
  118 |     file << "}]" << file;
      |     ~~~~~~~~~~~~ ^~ ~~~~
      |          |          |
      |          |          std::fstream {aka std::basic_fstream<char>}
      |          std::basic_ostream<char>

```

Solution:
```bash
sed -i 's/<< file/<< std::endl/' arcsim-0.3.1/src/sparse.hpp
```

### 4. `clamp` ambiguity
++ raises an error due to ambiguity between `clamp` defined in `arcsim-0.3.1/src/util.hpp` 
and `std::clamp` because of `using namespace std;` in multiple source files. 
So I just renames this function to `my_clamp`


Error message:
```
src/display.cpp: In function 'Vec3 strain_color(const Face*)':
src/display.cpp:116:24: error: call of overloaded 'clamp(double, double, double)' is ambiguous
  116 |     double tens = clamp(1e2*s0, 0., 0.5), comp = clamp(-1e2*s1, 0., 0.5);
      |                   ~~~~~^~~~~~~~~~~~~~~~~
In file included from src/sparse.hpp:30,
                 from src/dde.hpp:30,
                 from src/cloth.hpp:30,
                 from src/simulation.hpp:30,
                 from src/display.hpp:30,
                 from src/display.cpp:27:
src/util.hpp:82:25: note: candidate: 'T clamp(const T&, const T&, const T&) [with T = double]'
   82 | template <typename T> T clamp (const T &x, const T &a, const T &b) {
      |                         ^~~~~
In file included from /usr/include/c++/11/algorithm:62,
                 from /usr/include/boost/iterator/iterator_concepts.hpp:26,
                 from /usr/include/boost/range/concepts.hpp:20,
                 from /usr/include/boost/range/size_type.hpp:20,
                 from /usr/include/boost/range/size.hpp:21,
                 from /usr/include/boost/range/functions.hpp:20,
                 from /usr/include/boost/range/iterator_range_core.hpp:38,
                 from /usr/include/boost/algorithm/string/replace.hpp:16,
                 from /usr/include/boost/date_time/date_facet.hpp:17,
                 from /usr/include/boost/date_time/gregorian/gregorian_io.hpp:16,
                 from /usr/include/boost/date_time/gregorian/gregorian.hpp:31,
                 from /usr/include/boost/date_time/posix_time/time_formatters.hpp:12,
                 from /usr/include/boost/date_time/posix_time/posix_time.hpp:24,
                 from src/timer.hpp:34,
                 from src/simulation.hpp:36,
                 from src/display.hpp:30,
                 from src/display.cpp:27:
/usr/include/c++/11/bits/stl_algo.h:3656:5: note: candidate: 'constexpr const _Tp& std::clamp(const _Tp&, 
const _Tp&, const _Tp&) [with _Tp = double]'
 3656 |     clamp(const _Tp& __val, const _Tp& __lo, const _Tp& __hi)
      |     ^~~~~

```

Solution:
```bash
sed -i 's/T clamp/T my_clamp/' arcsim-0.3.1/src/util.hpp
find arcsim-0.3.1/src/ -type f -exec sed -i 's/clamp(/my_clamp(/' {} \;
```


### 5. Rebind symbolic link `Makefile` to `Makefile.linux`
Initially `Makefile` is linked to `Makefile.mac`

Error message:
```
g++: error: unrecognized command-line option '-framework'
```


Solution:
```bash
rm arcsim-0.3.1/Makefile
ln -s arcsim-0.3.1/Makefile.linux arcsim-0.3.1/Makefile
```