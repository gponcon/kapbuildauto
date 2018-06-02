#!/bin/sh

# By gponcon@gmail.com

CHARTSDIR='/opt/charts/imgkap/'
TMPFILE='/tmp/kapbuild.png'
TMPOCRFILE='/tmp/tesser'
OCRCONVPARAMS='-modulate 100,0,100 -brightness-contrast -30x80 -negate '
ALLCOORD='350x17+1400+1180'
OCRSED='s/^[^0-9]*\(-*[0-9.]*\).*$/\1/'
TRFR='!liIoODgB,*:JSAsq~'
TRTO='t11100098...33454-'
GOCROPT="-l 200 "
XCADRE=1834
YCADRE=1066
#XCOR=25
#YCOR=0

# Récup nom image
if [ $# != 1 ] ;then
  echo "Utilisation: kapbuild.sh <nomlieu>"
  exit
fi
IMGNAME=$CHARTSDIR$1
if [ -e $IMGNAME'.kap' ] ;then
  echo "Ce nom de lieu existe déjà"
  exit
fi
sleep 0.8

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
XLAT=`echo $COORDS     | tr $TRFR $TRTO | sed 's/‘/./g' | sed 's/—/-/g' | sed 's/^.*at *\([0-9.-]*\).*$/\1/'`
XLONG='-'`echo $COORDS | tr $TRFR $TRTO | sed 's/‘/./g' | sed 's/—/-/g' | sed 's/^.*0n9[^0-9]*\([0-9.-]*\).*$/\1/'`
if [ $XLAT'x' = 'x' ] ;then
  echo 'Latitude du coin supérieur gauche non trouvée';
  exit
fi
if [ $XLONG'x' = 'x' ] ;then
  echo 'Longitude du coin supérieur gauche non trouvée';
  exit
fi

# Déplacement bas droit
xte 'mousermove '$XCADRE' '$YCADRE
#xte 'mousermove '$XCOR' '$YCOR
sleep .1

scrot -z -c $TMPFILE
convert $TMPFILE $OCRCONVPARAMS -crop $ALLCOORD -resize 700x500 $TMPFILE'2.pnm'
tesseract $TMPFILE'2.pnm' $TMPOCRFILE -psm 7 > /dev/null 2> /dev/null
COORDS=`head -n 1 $TMPOCRFILE'.txt'`
echo 'Extract2 : '$COORDS
YLAT=`echo $COORDS     | tr $TRFR $TRTO | sed 's/‘/./g' | sed 's/—/-/g' | sed 's/^.*at *\([0-9.-]*\).*$/\1/'`
YLONG='-'`echo $COORDS | tr $TRFR $TRTO | sed 's/‘/./g' | sed 's/—/-/g' | sed 's/^.*0n9[^0-9]*\([0-9.-]*\).*$/\1/'`
if [ $YLAT'x' = 'x' ] ;then
  echo 'Latitude du coin inférieur droit non trouvée';
  exit
fi
if [ $YLONG'x' = 'x' ] ;then
  echo 'Longitude du coin inférieur droit non trouvée';
  exit
fi

# Saisie manuelle
#img2txt --width 150 $TMPFILE'1.pnm'
#echo 'Détecté: '$XLAT
#read -p 'Correction: ' NEWVAL
#if [ $NEWVAL'x' != 'x' ] ;then
#  XLAT=$NEWVAL
#else
#  XLAT=`echo $XLAT | sed $OCRSED`
#fi

#img2txt --width 150 $TMPFILE'2.pnm'
#echo 'Détecté: '$XLONG
#read -p 'Correction: ' NEWVAL
#if [ $NEWVAL'x' != 'x' ] ;then
#  XLONG=$NEWVAL
#else
#  XLONG='-'`echo $XLONG | sed $OCRSED`
#fi

#img2txt --width 150 $TMPFILE'3.pnm'
#echo 'Détecté: '$YLAT
#read -p 'Correction: ' NEWVAL
#if [ $NEWVAL'x' != 'x' ] ;then
#  YLAT=$NEWVAL
#else
#  YLAT=`echo $YLAT | sed $OCRSED`
#fi

#img2txt --width 150 $TMPFILE'4.pnm'
#echo 'Détecté: '$YLONG
#read -p 'Correction: ' NEWVAL
#if [ $NEWVAL'x' != 'x' ] ;then
#  YLONG=$NEWVAL
#else
#  YLONG='-'`echo $YLONG | sed $OCRSED`
#fi

echo 'Point 1 : '$XLAT' x '$XLONG
echo 'Point 2 : '$YLAT' x '$YLONG

# Extraction image
convert -crop $XCADRE'x'$YCADRE'+0+23' -quality 100 $TMPFILE $IMGNAME'.jpg'

# Création du KAP
~/bin/imgkap $IMGNAME'.jpg' $XLAT $XLONG $YLAT $YLONG $IMGNAME'.kap'
if [ $? != 0 ] ;then
  echo 'Conversion kap en échec'
  rm $IMGNAME'.kap'
  exit
fi
echo 'I: '$IMGNAME'.kap'
