#!/bin/bash
set -e

pushd `dirname $0`/.. > /dev/null
root=$(pwd -P)
popd > /dev/null

hash asciidoctor >/dev/null 2>&1 || gem install asciidoctor
hash asciidoctor-pdf >/dev/null 2>&1 || gem install --pre asciidoctor-pdf

source $root/ci/vars.sh

function doit {
    indir=$1
    outdir=$2

    aaa=`dirname $indir/index.txt`
    bbb=`basename $aaa`
    echo "Processing: $bbb/index.txt"

    # txt -> html
    asciidoctor -o $outdir/index.html $indir/index.txt  &> errs.tmp
    if [[ -s errs.tmp ]] ; then
        cat errs.tmp
        exit 1
    fi

    # txt -> pdf
    asciidoctor -r asciidoctor-pdf -b pdf -o $outdir/index.pdf $indir/index.txt  &> errs.tmp
    if [[ -s errs.tmp ]] ; then
        cat errs.tmp
        exit 1
    fi

    # if errs.tmp is empty, remove it
    [[ -s "errs.tmp" ]] || rm "errs.tmp"

    # copy images directory to out dir
    cp -R $indir/images $outdir

    # copy scripts directory to out dir
    cp -R $indir/scripts $outdir
}


function run_tests {
    # verify the example scripts
    echo Checking examples.

    echo "Checking section 3 examples"
    echo "Checking 3-hello.sh"
    $root/documents/userguide/scripts/3-hello.sh
    echo "Checking 3-hello-full.sh"
    $root/documents/userguide/scripts/3-hello-full.sh

    echo "Checking section 4 examples"
    cp $root/documents/userguide/scripts/terrametrics.tif $root
    echo "Checking 4-hosted-load.sh"
    jobid=`$root/documents/userguide/scripts/4-hosted-load.sh`
    echo "Checking 4-job.sh"
    dataid=`$root/documents/userguide/scripts/4-job.sh $jobid`
    echo "Checking 4-hosted-download.sh"
    $root/documents/userguide/scripts/4-hosted-download.sh $dataid
    # echo "Checking 4-nonhosted-load.sh"
    # jobid=`$root/documents/userguide/scripts/4-nonhosted-load.sh`
    # echo "Checking 4-job.sh"
    # dataid=`$root/documents/userguide/scripts/4-job.sh $jobid`
    # echo "Checking 4-nonhosted-wms.sh"
    # $root/documents/userguide/scripts/4-nonhosted-wms.sh $dataid
    rm $root/terrametrics.tif

    echo "Checking section 5 examples"

    echo "Checking section 6 examples"

    echo "Checking section 7 examples"

    echo Examples checked.
}

ins="$root/documents"
outs="$root/out"

[[ -d "$outs" ]] && rm -rf $outs

mkdir $outs

doit $ins $outs
doit $ins/userguide   $outs/userguide
doit $ins/devguide    $outs/devguide
doit $ins/devopsguide $outs/devopsguide

mkdir $outs/presentations
cp -f $ins/presentations/*.pdf $outs/presentations/

run_tests

echo Done.

tar -czf $APP.$EXT -C $root out
