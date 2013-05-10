set mozilla_path=src\github.com\mozilla-services
set git="c:\Program Files (x86)\Git\bin\git.exe"
set cwd=%CD%
IF NOT EXIST %mozilla_path% mkdir %mozilla_path%
IF NOT EXIST %mozilla_path%\heka cd %mozilla_path% && %git% clone https://github.com/mozilla-services/heka.git && cd heka && %git% submodule update --init --recursive
cd  %cwd%
IF NOT EXIST release mkdir release
cd release
cmake .. -G"MinGW Makefiles"
mingw32-make install
