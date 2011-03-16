#!/bin/sh
set -e

cur_dir=`pwd`
#root=`dirname $0`

shell_env=${cur_dir}/bin/shell-env.lua

echo "Preparing for testing shell-env"
echo "shell-env: $shell_env"

cat > ./env1 << "EOF"
export TEST_1="AAABBBCCC"
EOF

echo "precmd() {" > ./setshell
echo "eval \`$shell_env\`" >> ./setshell
echo "}" >> ./setshell
echo "PROMPT_COMMAND=precmd" >> ./setshell

#cat > ./env2 << "EOF"
#export TEST_1="AAA"
#export TEST_2="string1\"string2\"string3"

#EOF

sh_cmd() {
	eval `$shell_env`
}

unset TEST_1

(
lev1="dir space"
lev2="dir 2"

echo
echo "Testing for dir with whitespace"

mkdir -p "${lev1}/${lev2}"
cp ./env1 "${lev1}/.envrc"
cd "${lev1}/${lev2}"

sh_cmd

if (set|grep "TEST_1=AAABBBCCC") > /dev/null 2>&1
then
	echo Passed.
else
	echo Not passed!
fi

cd ../..
rm "${lev1}/.envrc"
rmdir -p "${lev1}/${lev2}"
)


unset TEST_1
(
echo
echo "Testing for variables with \""
lev1="dir1"
lev2="dir2"

mkdir -p "${lev1}/${lev2}"

orig='AAA"BBB'

cat > ${lev1}/.envrc << "EOF"
export TEST_1='AAA"BBB'
EOF

cd "${lev1}/${lev2}"

sh_cmd

if [ "$TEST_1" = "$orig" ]
then
	echo Passed.
else
	echo Not passed!
fi

cd ../..
rm "${lev1}/.envrc"
rmdir -p "${lev1}/${lev2}"
)


unset TEST_1
(
echo
echo "Testing for variables with \n"
lev1="dir1"
lev2="dir2"

mkdir -p "${lev1}/${lev2}"

orig="AAA
BBB
CCC"

cat > ${lev1}/.envrc << "EOF"
export TEST_1="AAA
BBB
CCC"
EOF
cd "${lev1}/${lev2}"

sh_cmd

if [ "$TEST_1" == "$orig" ]
then
	echo Passed.
else
	echo Not passed!
fi
cd ../..
rm "${lev1}/.envrc"
rmdir -p "${lev1}/${lev2}"
)

rm ./env1
#cd "$root/test/white space"
# Test that AAA1 is exported correctly
#shell-env | grep AAA1
# ...
