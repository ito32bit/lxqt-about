#!/bin/bash

mkdir -p list
base=$PWD/lxqt
outdir=$base/../list

cd $base
ts=`find . -name *_*$1.ts`
desktop=`find . -name *_*$1.desktop.yaml`
directory=`find . -name *_*$1.directory.yaml`
rm -vf $outdir/translators_*$1.gitlog

for fp in $ts $desktop $directory; do
  cd $base
  dir=${fp%/*}
  fn=${fp##*/}

  lang=${fp#*_}
  lang=${lang%%.*}
  outp=$outdir/translators_$lang.gitlog
  cd $dir
  echo "gitlog: $fn"
  echo -e "\nF:$fn" >> $outp
  git log --use-mailmap --no-merges --pretty=format:"%H" $fn | xargs -n1 git log -1 --numstat --shortstat --pretty=format:"H:%H%ns:%s%nA:%aN %aE%na:%an %ae%nD:%ai" >> $outp

done
