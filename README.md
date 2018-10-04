##Synopsis

Programme de démonstration de programmation en assembleur Intel 64 avec les instructions x87.
Affichage d'un ensemble de Mandelbrot en Ascii



##Dépendances

Presque rien, on utilise même pas la libc.
il faut nasm et ld pour complier par "make"



##Valeurs réglables et valeurs par défaut

Dimensions de l'écran, en nombre de caractère en mode texte
largeur_ecran	dd 300	; sur 32 bits pour faciliter fild
hauteur_ecran	dd 100

Fenêtre du plan complexe affichée
xmin		dq -2.25
xmax		dq 0.75
ymin		dq -1.5
ymax		dq 1.5

Nombre d'iération avant d'abandonner (pour les points dans l'ensemble de Mandelbrot)
max_iter	dq 64