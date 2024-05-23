#!/bin/bash

# By gponcon@gmail.com

CHARTSDIR='/opt/charts/imgkap/'
TMPFILE='/tmp/kapbuild.png'
TMPOCRFILE='/tmp/tesser'
OCRCONVPARAMS='-modulate 100,0,100 -brightness-contrast 0x90 -negate '
ALLCOORD='400x25+300+1047'
TRFR="\nS"
TRTO=' 5'
GOCROPT="-l 200 "
XCOR=0
YCOR=41
XCADRE=1920
YCADRE=975 # 1016-41
COORDSUBPATTERN='\([0-9°,'"'"']*\)"'
NSPATTERN='s/.*[NS]'$COORDSUBPATTERN'.*/\1/'
EWPATTERN='s/.*[EW]'$COORDSUBPATTERN'.*/\1/'

displayerror()
{
  zenity --error --title="kapbuildauto" --text="$*"
  exit 2
}

displayinfo()
{
  zenity --info --title="kapbuildauto" --text="$*"
}

if [ ! -f ~/.kapbuildauto ] ;then 
  displayerror "Fichier ~/.kapbuildauto pas trouvé"
  exit 2
fi

CPT=1
IMGPREFIX=$CHARTSDIR`head -n 1 ~/.kapbuildauto`'-'

IMGNAME=$IMGPREFIX`printf "%'05d" $CPT`
while [ -f $IMGNAME'.kap' ]
do
  CPT=`expr $CPT + 1`
  IMGNAME=$IMGPREFIX`printf "%'05d" $CPT`
done

# Move on left-top of the screen
xte 'mousemove '$XCOR' '$YCOR
sleep .1

# Coords extraction
scrot -z -c -o $TMPFILE
convert $TMPFILE $OCRCONVPARAMS -crop $ALLCOORD -resize 700x500 $TMPFILE'1.pnm'
tesseract $TMPFILE'1.pnm' $TMPOCRFILE > /dev/null 2> /dev/null
COORDS=`cat $TMPOCRFILE'.txt' | tr $TRFR $TRTO`
#displayinfo "Extract1 : $COORDS"
XLAT=`echo $COORDS | sed 's/ //g' | sed $NSPATTERN`'N'
XLONG=`echo $COORDS | sed 's/ //g' | sed $EWPATTERN`'W'

# Move on bottom right
xte 'mousermove '$XCADRE' '$YCADRE
sleep .1

scrot -z -c -o $TMPFILE
convert $TMPFILE $OCRCONVPARAMS -crop $ALLCOORD -resize 700x500 $TMPFILE'2.pnm'
tesseract $TMPFILE'2.pnm' $TMPOCRFILE > /dev/null 2> /dev/null
COORDS=`cat $TMPOCRFILE'.txt' | tr $TRFR $TRTO`
#displayinfo "'Extract2 : '$COORDS"
YLAT=`echo $COORDS | sed 's/ //g' | sed $NSPATTERN`'N'
YLONG=`echo $COORDS | sed 's/ //g' | sed $EWPATTERN`'W'

PT1='Point 1: '$XLAT' x '$XLONG
PT2='Point 2: '$YLAT' x '$YLONG
#displayinfo "$PT1 $PT2"

# Image extraction
convert -crop $XCADRE'x'$YCADRE'+'$XCOR'+'$YCOR -quality 97 $TMPFILE $IMGNAME'.jpg'

# KAP file build
~/bin/imgkap $IMGNAME'.jpg' "$XLAT" "$XLONG" "$YLAT" "$YLONG" $IMGNAME'.kap'

if [ $? != 0 ] ;then
  rm $IMGNAME'.kap'
  rm $IMGNAME'.jpg'
  displayerror "Echec de la conversion kap\n\n$PT1\n$PT2"
fi

# Sizes checks
JPGSIZE=`ls -s $IMGNAME'.jpg' | cut -d ' ' -f 1`
KAPSIZE=`ls -s $IMGNAME'.kap' | cut -d ' ' -f 1`
if [ $KAPSIZE < $JPGSIZE ] ;then
  rm $IMGNAME'.kap'
  rm $IMGNAME'.jpg'
  displayerror "Kap file size smaller than JPG\n\n$KAPSIZE < $JPGSIZE"
fi
if [ $KAPSIZE < 100 ] ;then
  rm $IMGNAME'.kap'
  rm $IMGNAME'.jpg'
  displayerror "Kap file size too small (${KAPSIZE}kb)"
fi

displayinfo $PT1"\n"$PT2"\nI: "$IMGNAME'.kap'
