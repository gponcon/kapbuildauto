#!/bin/bash

# By gponcon@gmail.com

CHARTSDIR='/opt/charts/imgkap/'
TMPFILE='/tmp/kapbuild.png'
TMPOCRFILE='/tmp/tesser'
#OCRCONVPARAMS='-modulate 100,0,100 -brightness-contrast -30x80 -negate '
OCRCONVPARAMS='-modulate 100,0,100 -brightness-contrast 0x90 -negate '
ALLCOORD='350x17+700+1180'
OCRSED='s/^[^0-9]*\(-*[0-9]*\).*$/\1/'
TRFR='!LliIoODgB,*:JSAsqT~'
TRTO='t111100098...334547-'
GOCROPT="-l 200 "
XCADRE=1838
YCADRE=1055
#XCADRE=1834
#YCADRE=1066
#XCOR=25
#YCOR=0

#sleep 1

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

IMGNAME=$IMGPREFIX`printf "%'03d" $CPT`
while [ -f $IMGNAME'.kap' ]
do
  CPT=`expr $CPT + 1`
  IMGNAME=$IMGPREFIX`printf "%'03d" $CPT`
done

# Déplacement haut gauche
xte 'mousemove 0 23'
#xte 'mousermove '$XCOR' '$YCOR
sleep .1

# Extraction coordonnées
scrot -z -c $TMPFILE
convert $TMPFILE $OCRCONVPARAMS -crop $ALLCOORD -resize 700x500 $TMPFILE'1.pnm'
tesseract $TMPFILE'1.pnm' $TMPOCRFILE -psm 7 > /dev/null 2> /dev/null
COORDS=`head -n 1 $TMPOCRFILE'.txt'`
echo 'Extract1 : '$COORDS
XLAT=`echo $COORDS     | tr $TRFR $TRTO | sed 's/—/-/g' | sed 's/^.*a1 *\([0-9.-]*\).*$/\1/'`
XLONG='-'`echo $COORDS | tr $TRFR $TRTO | sed 's/—/-/g' | sed 's/^.*0n9[^0-9]*\([0-9.-]*\).*$/\1/'`
if [ $XLAT'x' = 'x' ] ;then
  displayerror 'Latitude du coin supérieur gauche non trouvée'
fi
if [ $XLONG'x' = 'x' ] ;then
  displayerror 'Longitude du coin supérieur gauche non trouvée'
fi

# Déplacement bas droit
xte 'mousermove '$XCADRE' '$YCADRE
sleep .1

scrot -z -c $TMPFILE
convert $TMPFILE $OCRCONVPARAMS -crop $ALLCOORD -resize 700x500 $TMPFILE'2.pnm'
tesseract $TMPFILE'2.pnm' $TMPOCRFILE -psm 7 > /dev/null 2> /dev/null
COORDS=`head -n 1 $TMPOCRFILE'.txt'`
echo 'Extract2 : '$COORDS
YLAT=`echo $COORDS     | tr $TRFR $TRTO | sed 's/—/-/g' | sed 's/^.*a1 *\([0-9.-]*\).*$/\1/'`
YLONG='-'`echo $COORDS | tr $TRFR $TRTO | sed 's/—/-/g' | sed 's/^.*0n9[^0-9]*\([0-9.-]*\).*$/\1/'`
if [ $YLAT'x' = 'x' ] ;then
  displayerror 'Latitude du coin inférieur droit non trouvée'
fi
if [ $YLONG'x' = 'x' ] ;then
  displayerror 'Longitude du coin inférieur droit non trouvée'
fi

PT1='Point 1 : '$XLAT' x '$XLONG
PT2='Point 2 : '$YLAT' x '$YLONG
echo $PT1
echo $PT2

# Extraction image
convert -crop $XCADRE'x'$YCADRE'+0+23' -quality 100 $TMPFILE $IMGNAME'.jpg'

# Création du KAP
~/bin/imgkap $IMGNAME'.jpg' $XLAT $XLONG $YLAT $YLONG $IMGNAME'.kap'
if [ $? != 0 ] ;then
  rm $IMGNAME'.kap'
  displayerror "Conversion kap en échec\n\n$PT1\n$PT2"
fi
MSG=$PT1"\n"$PT2"\nI: "$IMGNAME'.kap'

displayinfo $MSG
