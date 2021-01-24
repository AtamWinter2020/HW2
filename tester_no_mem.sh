#!/bin/bash
exec 2> /dev/null
testdir="$(pwd)/tests"
indir="${testdir}/in"
outdir="${testdir}/out"
errdir="${testdir}/err"
tempdir="${testdir}/temp"
all_pass="true"

msg1="!!!!ALL Logic Tests Passed!!!!"


if [ "$#" -ne 1 ]
then
   echo "usage: \"tester <path to executable>\""
   exit
fi
exe=$1

mkdir -p "${tempdir}"
rm -rf "${tempdir}/*"
rm -rf "${errdir}/*.txt"
temp_infiles="$(find "${indir}" -type f -printf '%p;')"
oldIFS=$IFS
IFS=';'
infiles=($temp_infiles)
IFS=$oldIFS

echo "Running logic tests"
for filename in "${infiles[@]}";do
    file=${filename##*/}
    in_prefix=${file:0:2}
    if [[ $in_prefix -eq "in" ]]
    then
        suffix=${file:2}
        outfile=${outdir}/out${suffix}
        errfile=${errdir}/out${suffix}
        if test -f "$outfile"; then
            ./${exe} < "${indir}/${file}">"${tempdir}/${suffix}" || segfault="true"

            if [[ "${segfault}" == "true" ]]; then
                echo "${file} runtime error or segfault"
                segfault="false"
                all_pass="false"
                
                continue 
            fi
            diff_result=$(diff "${outdir}/out${suffix}" "${tempdir}/${suffix}") 
            if [[ "$diff_result" != "" ]]
            then
                echo "${file} failed"
                all_pass="false"
            else
                echo "${file} succeeded"
                mkdir -p "${errdir}"
                echo "${diff_result}" > "${errdir}/${suffix}"
            fi
        else
            echo "${file} out file  missing"
        fi
    fi
done


if [[ "$all_pass" == "true" ]];then
    echo $msg1
fi

exec 2> /dev/tty
exit
