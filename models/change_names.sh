#!/bin/bash

find . -type f  | xargs -I{} bash -c 'mv -v ${0} ${0/_part/}' {};
find . -type f  | xargs -I{} bash -c 'mv -v ${0} ${0/stefan/ikea_stefan}' {};

