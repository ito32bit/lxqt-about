#!/bin/bash

. developers.list
. mailmap_manual

cd list
for fp in `find . -name "translators_*$1.gitlog"` ; do
  declare -A list=()
  
  lang=${fp#*_}
  lang=${lang%.*}
  outfp=${fp%.*}.info
  fp_manual="../translators_manual/"$outfp
  if [[ -e $fp_manual ]] ; then
    echo Read: $fp_manual
    IFS=$'\n'
    for line in `cat $fp_manual` ; do
      unset IFS
      case $line in
        translator_*_nameEnglish*)
          author=${line#*= }
          author=${author% }
          let list["${map_manual[$author]:-$author}"]=0
          ;;
        translator_*_contact*)
          unset list["${map_manual[$author]:-$author}"]
          mail=${line#*= }
          mail=${mail// /+}
          mail=${mail//[<>]/}
          author="$author $mail"
          let list["${map_manual[$author]:-$author}"]=0
          ;;
      esac
    done
  fi

  echo -n "$outfp "
  IFS=$'\n'
  for line in `cat $fp` ; do
    unset IFS
    case ${line:0:1} in
      "F")
        filename=${line#??}
        echo -n "."
        ;;
      "A")
        author=${line#??}
        dev=false
        let count=0
        for a in ${developers[${author##* }]} ; do
          dev=true
          if [[ $a == $lang ]] ; then
            dev=false
            break
          fi
        done
        ;;
      " ")
        if ! $dev && (( $count > 0 )) ; then
          let list["$author"]=list["$author"]+count
        fi
        ;;
      [0-9])
        if ! $dev ; then
          if [[ $line =~ .*$filename ]] ; then
            let count=count+${line%%$'\t'*}
          elif ! [[ $line =~ .*(\.ts|\.desktop\.in|\.desktop|\.directory\.in|\.directory|\.yaml|CMakeLists.txt) ]] ; then
            dev=true
          elif [[ $line =~ .*/[^_]*_(..).*\.(ts|desktop|directory|yaml) ]] ; then
            if [[ ${BASH_REMATCH[1]} != ${lang:0:2} ]] ; then
                dev=true
            fi
          fi
        fi
        ;;
    esac
  done
  
  unset IFS
  all=$(
    for author in "${!list[@]}"; do
      echo ${list[$author]} $author
    done | sort -k2 -f  # sort by Author
    #done | sort -nr     # sort by Count
  )
  
  header="#
# DO NOT EDIT THIS FILE
#
# It is automatically generated by script
#

"
  oneline="#[Lang] Lines <Mail> Name"$'\n'
  info=""
  IFS=$'\n'
  num=1
  for line in $all; do
    count=${line%% *}
    author=${line#* }
    author=${author% *}
    mail=${line##* }
    if [[ $mail =~ (.*)@users.noreply.github.com ]]; then
      mail=https://github.com/${BASH_REMATCH[1]#*+}
    fi
    printf -v str "%5d %-40s" $count "<$mail>"
    oneline=$oneline"#[$lang] $str $author"$'\n'
    info=$info$'\n'"translator_${num}_nameEnglish = $author"$'\n'
    if [[ "$mail" != "@" ]] ; then
      info=$info"translator_${num}_contact = $mail"$'\n'
    fi
    let num++
  done
  if [[ "$info" == "" ]] ; then
    echo -n "R"
    rm -f $outfp
  else
    echo "$header$oneline$info" > $outfp
  fi
  echo
done
