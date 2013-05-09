set mozilla_path=src\github.com\mozilla-services
IF NOT EXIST %mozilla_path% mkdir %mozilla_path%
IF NOT EXIST release mkdir release
cd release
cmake .. -G"MinGW Makefiles"
mingw32-make
