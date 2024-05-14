#!/bin/bash

echo "compiling..."
# libjq.a is in loki/build and libonig.a is in loki/build/thirdparty/jq/modules/oniguruma
g++ -std=c++17 main.cpp stuff.cpp -ljq -lonig -o jqtool
echo "done!"
