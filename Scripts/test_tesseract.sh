#!/bin/zsh -f

scriptpath=$0:A
parentdir=${scriptpath%/*}
scriptname=${scriptpath##*/}
builddir=$parentdir/build

if ! source $builddir/project_environment.sh; then
  echo "test_tesseract.sh: error sourcing $builddir/project_environment.sh"
  exit 1
fi

echo '# Checking for Trained Data Language Files'

langfiles=(
  'chi_tra.traineddata'
  'chi_tra_vert.traineddata'
  'eng.traineddata'
  'jpn.traineddata'
  'jpn_vert.traineddata'
)

# Download jpn and jpn_vert files
for langfile in $langfiles; do
  if [ -f $ROOT/share/tessdata/$langfile ]; then
    echo "found $langfile"
    continue
  fi

  mkdir -p $ROOT/share/tessdata

  print -n "downloading $langfile..."
  curl -L -f -s \
    https://github.com/tesseract-ocr/tessdata_best/raw/master/$langfile \
    --output $ROOT/share/tessdata/$langfile
  print 'done'
done

strip_whitespace() {
  local filename=$1

  cat $filename | tr -d '\n' | tr -d '\f' | tr -d ' '
}

test_image() {
  # Run tesseract command-line program on a number of sample/test images;
  #
  #   tesseract CL program should be in Root/bin, and Root/bin is
  #   added to $PATH in project_environment.sh
  local testName=$1
  local image=$2
  local trainedDataName=$3
  local whtspcStrippedWant=$4

  print -n "testing $testName..."

  local tessOutFile=$trainedDataName

  # Clear any previous and lingering state
  rm -f $tessOutFile.txt

  # `$tessOutFile` param directs tesseract to create $tessOutFile.txt
  tesseract $image $tessOutFile -l $trainedDataName 2>/dev/null
  got=$(strip_whitespace $tessOutFile.txt)

  if [ $got = $whtspcStrippedWant ]; then
    print 'passed'
  else
    print "*failed*: got '$got', want '$whtspcStrippedWant'"
  fi
}

echo '# Recognizing Sample Images'

ASSETSDIR=$PROJECTDIR/iOCR/iOCR/Assets.xcassets
TESTDIR=tesseractTest

mkdir -p $TESTDIR; cd $TESTDIR || exit 1

vars=(
  'Japanese horizontal'
  $ASSETSDIR/japanese.imageset/test_hello_hori.png
  'jpn'
  'Hello,世界'
)
test_image $vars

vars=(
  'Japanese vertical'
  $ASSETSDIR/japanese_vert.imageset/test_hello_vert.png
  'jpn_vert'
  'Hello,世界'
)
test_image $vars

vars=(
  'Traditional Chinese vertical'
  $ASSETSDIR/chinese_traditional_vert.imageset/cropped.png
  'chi_tra_vert'
  '哈哈我第一個到終點了!'
)
test_image $vars

vars=(
  'English (left-justified, square aspect)'
  $ASSETSDIR/english_left_just_square.imageset/hexdreams.png
  'eng'
  "WelcometoHexdreamer'sdreamofasimple-to-followguideforaddingaC-API,andspecificallyTesseractOCR'sC-API,intoanXcodeprojectforuseinadreamiOSmanga-readerapp."
)
test_image $vars

cd ..; rm -rf $TESTDIR