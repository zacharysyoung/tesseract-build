#!/bin/zsh -f

build_scripts=()
while IFS='' read -r line; do
  build_scripts+=($line)
done < <(find build -name '*.sh')

readonly FILES_TO_CHECK=(
  $build_scripts
  precommit-check.sh
)

check_shebang() {
  local files=($@)

  local _status=0
  for _file in $files; do
    shebang=$(head -n1 $_file)
    if [[ ! $shebang =~ '#!/bin/zsh' ]]; then
      echo "$_file: wanted shebang '#!/bin/zsh', got '$shebang'"
      _status=1
    fi
  done

  return $_status
}

status=0
# bash is close enough; disable specific checks in $PROJECTDIR/.shellcheckrc
errors=$(shellcheck -f gcc -s bash $FILES_TO_CHECK)
if [[ -n $errors ]]; then
  echo The following errors need to be resolved before checkin
  echo $errors
  status=1
fi

formatted_files=$(shFmt -l -i 2 -ci -w $FILES_TO_CHECK)
if [[ -n $formatted_files ]]; then
  echo The following files were formatted by shFmt
  echo $formatted_files
  status=1
fi

shebangs=$(check_shebang $FILES_TO_CHECK)
if [[ -n $shebangs ]]; then
  echo The following shebangs need to be corrected
  echo $shebangs
  status=1
fi

if [ $status -eq 1 ]; then
  exit 1
fi

exit 0

# For future reference...

#
# How to work with git and staged files during pre-commit
#

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  against=HEAD
else
  # Initial commit: diff against an empty tree object
  against=$(git hash-object -t tree /dev/null)
fi

# :0:FNAME means 'stage 0 entry', or just "staged"
for fname in $(git diff --cached --name-only $against); do
  git cat-file -p :0:$fname >tmpfile
  # check $tmpfile || echo Problem w/$fname

  # not sure about running shFmt because not sure
  # how to get change staged... other than simply
  # doing it and seeing how I like precommit changing
  # stuff on me
  # expect, if there's an edit and no unstaged changes for
  # file, then
  # mv tmpfile $fname
done

#
# Working with shunit2
#

export SHUNIT_COLOR=none
_errs=$(${_SCRIPTSDIR}/run_tests.sh)
_status=$?
if [ $_status -ne 0 ]; then
  msg=
  msg=$_errs
  if [ "$errs" = "" ]; then
    errs="$msg"
  else
    errs="$errs\n$msg"
  fi
fi

if [ "$errs" != "" ]; then
  echo "$errs"
  echo
  exit 1
fi
