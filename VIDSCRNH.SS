; /// > HARDWARE LAYER / VIDEL / REGISTER SCANNER  - Kochise 2000/2001 < ///

; Da purpose of this software is to create a lil' file which contain all
; the current VIDEL Register Values and some calculations.

	comment	HEAD=7

; /////////////////////////////////////////////////////////////////////////////	
	SECTION	TEXT
; /////////////////////////////////////////////////////////////////////////////	
	
	; *** Lib‚ration de la M‚moire ************************
	;
	; On commence par lib‚rer la TPA
	
ZOS_VRSCAN_MTEXT_START:	movea.l	(4,SP),A6	; Adresse de la BASEPAGE
	move.l	($C,A6),D0	; Taille du SEGMENT TEXT
	add.l	($14,A6),D0	; Additionne la taille du SEGMENT DATA … D0
	add.l	($1C,A6),D0	; Additionne la taille du SEGMENT BSS … D0
	addi.l	#$100,D0	; Additionne la taille de la BASEPAGE … D0
	addi.l	#$400,D0	; Additionne la taille de la future PILE (Ici, 256 positions longues (1024 OCTETS))
	move.l	D0,D1	; Copie D0 dans D1 (Taille … r‚server)
	move.l	D0,D7
	add.l	A6,D1	; Additionne l'adresse du d‚but du programme avec D1 (La taille … r‚server)
	andi.l	#-2,D1	; Rend D1 pair (Au cas o— il ne l'‚tait pas)
	subq.l	#8,D1	; Garde de la place pour l'adresse de la BASEPAGE
	move.l	(4,SP),D2	; Sauvegarde l'adresse de la BASEPAGE
	movea.l	D1,SP	; Installe l'adresse de fin du programme+place nouvelle PILE dans la PILE
	move.l	D2,(4,SP)	; R‚installe l'adresse de la BASEPAGE
	move.l	D0,-(SP)	; EmPILE la taille … r‚server
	move.l	A6,-(SP)	; EmPILE l'adresse du programme
	clr.w	-(SP)	; R‚serv‚
	move.w	#$4A,-(SP)	; - M_SHRINK -
	trap	#1	; *** GEMDOS ***
	lea	(12,SP),SP
	
	; *** Lit les Donn‚es LineA ***************************
	;
	; Quelques Infos, quoique je recalcule plus pr‚cis‚ment
	; ZOS_VRSCAN_BSS_LAPR et que je n'utilise finalement pas
	; ZOS_VRSCAN_BSS_LALS...
	
	dc.w	$A000	; - LineA INIT -
	
	move.w	(-12,A0),ZOS_VRSCAN_BSS_LAHR
	move.w	(-4,A0),ZOS_VRSCAN_BSS_LAVR
	move.w	(A0),ZOS_VRSCAN_BSS_LAPR
	move.w	(2,A0),ZOS_VRSCAN_BSS_LALS
	
	; *** Lecture des Registres VIDEL *********************
	;
	; Les registres n'‚tants accessibles qu'en SUPERVISEUR,
	; je passe donc la Routine de Lecture en SUPEXEC...
	
	pea	ZOS_VRSCAN_SSTEXT_VREAD
	move.w	#$26,-(SP)	; - SUPEXEC -
	TRAP	#14	; *** XBIOS ***
	addq.l	#6,SP
	
	; *** Cr‚ation du Chemin de Sauvegarde ****************
	;
	; En fait, on va sauver le Fichier que l'on va cr‚er dans
	; le R‚pertoire Courant.
	
	; De ce fait, on commence par demander l'Unit‚ Disque en
	; cours...

	move.w	#$19,-(SP)	; - D_GETDRV -
	TRAP	#1	; *** GEMDOS ***
	addq.l	#2,SP

	; Si c'est plus que 'Z', c'est entre '1' et '6' sur ATARI

	cmpi.w	#26,D0
 	BGE	ZOS_VRSCAN_MTEXT_BDOS
 	
 	add.w	#'A',D0	; A..Z
 	
 	BRA	ZOS_VRSCAN_MTEXT_PATH
 	
ZOS_VRSCAN_MTEXT_BDOS:	add.w	#'0'-26,D0	; 1..6
		
	; On mets en place l'Identification de l'Unit‚ Disque
	; Si c'est 'C', on va ‚crire : 'C:\'
		
ZOS_VRSCAN_MTEXT_PATH:	lea	ZOS_VRSCAN_BSS_FILEP,A5
	move.b	D0,(A5)+
	move.b	#':',(A5)+
	
	; On ajoute le Chemin Courant
	; Si c'est 'C:\TOTO\HEROS', la Fonction place
	; 'TOTO\HEROS'
	
  	clr.w	-(SP)
 	move.l	A5,-(SP)
 	move.w	#$47,-(SP)	; - D_GETPATH -
 	trap	#1	; *** GEMDOS ***
 	addq.l	#8,SP

	; On se m‚fie du pointeur, on se replace … la Fin du
	; Chemin, et on cloture avec un '\'.
	; Au final, avec l'exemple pr‚c‚dent, on fini par
	; obtenir 'C:\TOTO\HEROS\'.
	; Il ne reste plus qu'a mettre un dernier sous-R‚pertoire
	; en fonction du Type de Moniteur, puis le Nom du
	; Fichier que l'on d‚finira plus loin en fonction
	; de la r‚solution de l'Ecran.

	lea	ZOS_VRSCAN_BSS_FILEP,A0
	BSR	ZOS_VRSCAN_USTEXT_ENDS
	move.b	#'\',(A0)+
	movea.l	A0,A5
	
	; *** V‚rifie le Type d'Ecran et modifie le Chemin
	;
	; Donc l…, je modifie le Chemin pour ajouter un
	; sous-R‚pertoire en fonction du Type de Moniteur.
	;
	; ATTENTION : Je ne fais ici AUCUNE v‚rification par
	;             rapport … l'existance de ces sous-R‚pertoires.
	;             En somme, j'me suis pas foul‚e, je les ais
	;             fais … la main.
	;             Une modification (pas vraiment n‚cessaire)
	;             consisterait … faire cette v‚rification,
	;             et cr‚er les sous-R‚pertoires le cas
	;             ‚ch‚ant.
	;
	; ASTUCE : Les cr‚er d'embler, sans s'inquieter s'ils
	;          existent d‚j… ou non. S'ils existent d‚j…, on
	;          obtient une erreur, et c'est pas grave.
	;          On passe au suivant, etc...
	
	move.w	ZOS_VRSCAN_BSS_RCO,D0
	andi.w	#%11,D0	; MonType

	lea	ZOS_VRSCAN_DATA_MONTAB,A4
	movea.l	(A4,D0.w*4),A4	; MonText
	
	movea.l	A4,A0
	movea.l	A5,A1
	
	BSR	ZOS_VRSCAN_USTEXT_SCPY	
	
	; Notez ici que je 'sauvegarde' la position de la fin
	; du Chemin en A5, ou l'on mettra le Nom du Fichier par
	; la suite...
	; Vu que l'on va tester l'existance des Fichiers d‚j…
	; existants, le mieux est encore de garder un doigt l…
	; dessus...
	
	movea.l	A1,A5	; EndPath
	
	; *** Cr‚ation du Nom du Fichier de Sauvegarde
	;
	; L…, c'est un peu la zone, d‚sol‚e.
	; Si vous ˆtes en 768*576 en 16 couleurs
	; (4 plans, ou disons 4 bits par couleur), il
	; va sagit de g‚n‚rer le Nom de Fichier suivant :
	; '76857604.xxx', o— 'xxx' est un nombre compris
	; entre '001' et '999'. On ne se pr‚occupera pas
	; ici d'un quelconque test de limite.
	; En effet, le 'xxx' est le num‚ro de Fichier ayant
	; d‚j… ce nom. Si '76857604.001' existe, et que
	; vous relancez le logiciel, vous obtiendrez
	; '76857604.002'. Donc d'ici … ce que vous fassiez
	; '999' fois le meme fichiers...

	lea	ZOS_VRSCAN_BSS_FILEN,A3

	; --- Horizontal
	
	lea	ZOS_VRSCAN_BSS_LAHR,A0
	lea	ZOS_VRSCAN_BSS_FILET,A1	; Tempo FICHIER
	clr.w	D0	; WORD
	BSR	ZOS_VRSCAN_USTEXT_UW2AD
	
	clr.b	(A1)+	; Assure les arriŠres
	
	; Taille STR
	
	lea	ZOS_VRSCAN_BSS_FILET,A0
	BSR	ZOS_VRSCAN_USTEXT_SLEN
	
	; On complete avec des '0'
	; Ben oui, si on obtient '65', on veut '065'
	; '65' c'est 2 caractŠres. 3-2=1 * '0' … mettre
	; STEP 1 : On ne fait rien au d‚part, juste un DBF
	;          qui descend le compteur … 0.
	; STEP 2 : L… on place notre '0', mais on n'y repasse
	;          pas … cause du DBF … 0...
	;
	; Si j'ai un '768' pas exemple, 3 caractŠres, j'ai
	; donc 0 '0' … placer. Un 0 dans D1, et on passe
	; le DBF dans la foul‚e. Malin, hein ?
	
	moveq.w	#3,D1
	sub.w	D0,D1
	
	BRA	ZOS_VRSCAN_MTEXT_FNHRL
	
ZOS_VRSCAN_MTEXT_FNHRF:	move.b	#'0',(A3)+

ZOS_VRSCAN_MTEXT_FNHRL:	DBF	D1,ZOS_VRSCAN_MTEXT_FNHRF

	; Et hop, on copie ce que l'on vient de faire (HRez)

	lea	ZOS_VRSCAN_BSS_FILET,A0
	movea.l	A3,A1	; FILEN
	BSR	ZOS_VRSCAN_USTEXT_SCPY
	
	; On garde la fin (actuelle) du Nom du Fichier en A3
	; comme on garde en A5 la fin du Chemin (souvenez vous
	; un peu plus haut)
	
	movea.l	A1,A3

	; --- Vertical
	;
	; Bon, meme topo pour la R‚so Verticale. J'r'explique pas
	
	lea	ZOS_VRSCAN_BSS_LAVR,A0
	lea	ZOS_VRSCAN_BSS_FILET,A1
	clr.w	D0
	
	BSR	ZOS_VRSCAN_USTEXT_UW2AD
	
	clr.b	(A1)+
	
	; Taille STR
	
	lea	ZOS_VRSCAN_BSS_FILET,A0
	
	BSR	ZOS_VRSCAN_USTEXT_SLEN
	
	; On complete avec des '0'
	
	moveq.w	#3,D1
	sub.w	D0,D1
	
	BRA	ZOS_VRSCAN_MTEXT_FNVRL
	
ZOS_VRSCAN_MTEXT_FNVRF:	move.b	#'0',(A3)+

ZOS_VRSCAN_MTEXT_FNVRL:	DBF	D1,ZOS_VRSCAN_MTEXT_FNVRF

	lea	ZOS_VRSCAN_BSS_FILET,A0
	movea.l	A3,A1
	BSR	ZOS_VRSCAN_USTEXT_SCPY

	movea.l	A1,A3

	; --- Plan
	;
	; Heu, l… je vous doit quelques explication tout de meme.
	; L'info LAPR retourn‚e par la LineA n'est pas toujours
	; fiable. Ducoup je la recalcule...
	; LALS est la longueur d'une ligne en BYTE (!!!).
	; Avec 320 pixels en mono, LALS fait 40.
	; Je multiplie 40 par 8, j'obtient 320, que je divise
	; par mes 320 pixels, et j'obtient 1 bit par couleur.
	; Si … pr‚sent j'ai toujours mes 320 pixels de large, mais
	; avec un LALS de 640, j'ai donc un WORD par Pixel.
	; 640 * 8 me donne 5120, que je divise ensuite par mes
	; 320 Pixels pour obtenir, je vous le donne en mille,
	; 16 Bits par Pixels. Admirez l'artiste...

	move.w	ZOS_VRSCAN_BSS_LALS,D0
	mulu.w	#8,D0
	
	move.w	ZOS_VRSCAN_BSS_LAHR,D1
	divu.w	D1,D0
	
	; On sauve pour la suite
	
	move.w	D0,ZOS_VRSCAN_BSS_LAPR
	
	; Et puis l…, meme topo que tout … l'heure, on
	; converti en ASCII pour le nom du Fichier
	
	lea	ZOS_VRSCAN_BSS_LAPR,A0
	lea	ZOS_VRSCAN_BSS_FILET,A1
	clr.w	D0
	
	BSR	ZOS_VRSCAN_USTEXT_UW2AD
	
	clr.b	(A1)+
	
	; Taille STR
	
	lea	ZOS_VRSCAN_BSS_FILET,A0
	
	BSR	ZOS_VRSCAN_USTEXT_SLEN
	
	; On complete avec des '0'
	; Ha oui, l… uniquement 2 caractŠres
	; Je doute que l'on puisse trouver plus de 99 Bits
	; par Pixel sur Falcon030 ;) )
	; Et puis je n'ai que 8 chars pour le nom du fichier :
	; 3 pour la r‚so Horizontale
	; 3 pour la R‚so Verticale
	; Reste 2 pour le Nombre de Bits par Pixel
	; C'est beau tout ‡a, et je m'aime (biz)...
	
	moveq.w	#2,D1
	sub.w	D0,D1
	
	BRA	ZOS_VRSCAN_MTEXT_FNPRL
	
ZOS_VRSCAN_MTEXT_FNPRF:	move.b	#'0',(A3)+

ZOS_VRSCAN_MTEXT_FNPRL:	DBF	D1,ZOS_VRSCAN_MTEXT_FNPRF

	lea	ZOS_VRSCAN_BSS_FILET,A0
	movea.l	A3,A1
	BSR	ZOS_VRSCAN_USTEXT_SCPY

	; Pas la peinr de sauver quoi que ce soit ici, on y est

	; --- Extension

	; Ze '.', mais l… on sauve pour la modification de
	; l'extension au besoin.
	; N'oubliez pas qu'en A5, il reste la fin du Chemin
	; Donc A4, le d‚but de l'extension...

	move.b	#'.',(A1)+
	movea.l	A1,A4
		
	; On commence … '001'
		
	moveq.w	#1,D6
		
	; Donc l…, on convertit le num‚ro de l'extension,
	; avec la meme recette qu'avant.
	; Oui je sais, l… y'aurait … optimiser pas mal,
	; avec une sous-routine par exemple...
		
ZOS_VRSCAN_MTEXT_TSTF:	move.w	D6,ZOS_VRSCAN_BSS_TEMPONUM
	movea.l	A4,A3

	lea	ZOS_VRSCAN_BSS_TEMPONUM,A0
	lea	ZOS_VRSCAN_BSS_FILET,A1
	clr.w	D0
	
	BSR	ZOS_VRSCAN_USTEXT_UW2AD
	
	clr.b	(A1)+
	
	; Taille STR
	
	lea	ZOS_VRSCAN_BSS_FILET,A0
	
	BSR	ZOS_VRSCAN_USTEXT_SLEN
	
	; On complete avec des '0'
	
	moveq.w	#3,D1
	sub.w	D0,D1
	
	BRA	ZOS_VRSCAN_MTEXT_FNEXL
	
ZOS_VRSCAN_MTEXT_FNEXF:	move.b	#'0',(A3)+

ZOS_VRSCAN_MTEXT_FNEXL:	DBF	D1,ZOS_VRSCAN_MTEXT_FNEXF

	lea	ZOS_VRSCAN_BSS_FILET,A0
	movea.l	A3,A1

	BSR	ZOS_VRSCAN_USTEXT_SCPY

	; *** Copie du Nom et de L'extension Finale
	;
	; L… le nom du Fichier est pret, rest plus qu'… le placer
	; … la fin du chemin (en A5 pour ceux qui ne suivent plus)
	
	lea	ZOS_VRSCAN_BSS_FILEN,A0
	movea.l	A5,A1
	BSR	ZOS_VRSCAN_USTEXT_SCPY
	
	; On s'assure de la propret‚ de la chaine de caractŠre
	; Un peu d'hygiŠne n'a JAMAIS fait de mal

	clr.b	(A1)+

	; *** V‚rification d'existance du Nom du Fichier
	;
	; Simple, on ouvre le fichier en lecture
	; Si tout se passe correctement, c'est que le fichier
	; existe d‚j…
	
	clr.w	-(SP)
	pea	ZOS_VRSCAN_BSS_FILEP
	move.w	#$3D,-(SP)	; - F_OPEN -
	TRAP	#1	; *** GEMDOS ***
	addq.l	#8,SP
	
	tst.l	D0
	BMI	ZOS_VRSCAN_MTEXT_NOFILE
	
	; *** Modification de l'Extension
	;
	; Bon, l… c'est que le fichier existe d‚j….
	; On modifie le num‚ro de l'extension, et on referme le
	; fichier que l'on vient d'ouvrir (un peu par erreur)
	
	addq.w	#1,D6
	
	; --- On ferme le Fichier ouvert

	move.w	D0,-(SP)
	move.w	#$3E,-(SP)	; - F_CLOSE -
	TRAP	#1	; *** GEMDOS ***
	addq.l	#4,SP	

	; Et on s'en va juste reconvertir la nouvelle extension
	
	BRA	ZOS_VRSCAN_MTEXT_TSTF
	
	; *** Copie du Header
	;
	; Bon, l… c'est que le fichier n'existe pas et que l'on
	; s'est pris une erreur dans les gencives (f'est affez
	; douloureux)
	; Ce que l'on va faire ici, c'est copier l'Entete,
	; en y placant le type de moniteur (m‚thode employ‚e
	; lors de la cr‚tion du chemin).
	; OK OK, j'aurais encore put optimiser ici...

ZOS_VRSCAN_MTEXT_NOFILE: lea	ZOS_VRSCAN_DATA_HEADR1,A0
	lea	ZOS_VRSCAN_BSS_FILED,A1
	
	BSR	ZOS_VRSCAN_USTEXT_SCPY

	move.w	ZOS_VRSCAN_BSS_RCO,D0
	andi.w	#%11,D0	; MonType

	lea	ZOS_VRSCAN_DATA_MONTAB,A4
	movea.l	(A4,D0.w*4),A0	; MonText
		
	BSR	ZOS_VRSCAN_USTEXT_SCPY	
	
	subq.l	#1,A1

	lea	ZOS_VRSCAN_DATA_HEADR2,A0
	
	BSR	ZOS_VRSCAN_USTEXT_SCPY
	
	; *** Cr‚ation des Donn‚es
	;
	; Pour la cr‚ation des donn‚es, et les multiple conversions
	; … foisson, je n'ai pas voulue me 'fouler'. Du coup, j'ai
	; mis au point une sorte de petit interpreteur et un systŠme
	; d'opcodes.
	; J'vous l'avais dis, j'me suis pas foul‚e...
	
	; --- Taille Ecran
	;
	; Heu, l… en fait y'a juste quelques calcul pr‚liminaires
	; que j'avais oubli‚e de faire plus haut. Honte … moi...
	
	clr.l	D0
	clr.l	D1
	move.w	ZOS_VRSCAN_BSS_VWRAP,D0
	lsl.l	#1,D0
	move.w	ZOS_VRSCAN_BSS_LAVR,D1
	mulu.l	D0,D1
	move.l	D1,ZOS_VRSCAN_BSS_SSIZ
	
	; Initialisation de l'interpreteur
	; A4 : Fetcher
	; A5 : Routines
	; A6 : Program to read
	
	; Le premier WORD est la commande, les WORDs ou LONGs suivant
	; sont les paramŠtres. En fonction de la commande … effectuer,
	; il y a plus ou moins de paramŠtres … charger. Une fois ceux-ci
	; charg‚s, on pointe (th‚oriquement) la commande suivante.
	
	; On commence par lire le num‚ro de commande. En fonction
	; de celui-ci, on execute le FETCHER et la ROUTINE
	; correspondante.
	
	; Le FETCHER charge les paramŠtres et le placent au bons endroits.
	; La ROUTINE s'execute d'elle meme, trouvant les paramŠtres juste
	; charg‚s aux bons endroits par le FETCHER.
	
	; Ensuite on recommence jusqu'… trouver la commande de fin (6)
	
	; Il va de sois qu'il est hors de question de toucher …
	; A4, A5 et A6 !!!
	
	; HORS DE QUESTION !!!
	
	; N'Y PENSEZ MEME PAS !!!
	
	; NON MAIS DES FOIS...
	
	lea	ZOS_VRSCAN_DATA_LDTAB,A4
	lea	ZOS_VRSCAN_DATA_CNVTAB,A5
	lea	ZOS_VRSCAN_DATA_REGTAB,A6

ZOS_VRSCAN_MTEXT_PROC:	move.w	(A6)+,D7	; COMMPTR
	
	cmpi.w	#6,D7
	BEQ	ZOS_VRSCAN_MTEXT_EPROC
	
	JSR	([A4,D7.w*4])	; FETCHER
	JSR	([A5,D7.w*4])	; ROUTINE
	
	BRA	ZOS_VRSCAN_MTEXT_PROC
	
	; On termine finalement le fichier
	;
	; PS : Une fois le fichier obtenu, il n'y a AUCUNE
	; Tabulation pour aligner les nombres. C'est ensuite …
	; faire … la main avec n'importe quel traitement de TXT...
	
ZOS_VRSCAN_MTEXT_EPROC:	move.l	#$0D0A0000,(A1)+

	; *** Cr‚ation du Fichier
	
	clr.w	-(SP)
	pea	ZOS_VRSCAN_BSS_FILEP
	move.w	#$3C,-(SP)	; - F_CREATE -
	TRAP	#1	; *** GEMDOS ***
	addq.l	#8,SP

	move.w	D0,D6

	; *** Calcul Taille du Fichier
	
	move.l	#ZOS_VRSCAN_BSS_FILED,A0
	
	BSR	ZOS_VRSCAN_USTEXT_SLEN

	; *** Sauvegarde des Donn‚es

	pea	ZOS_VRSCAN_BSS_FILED
	move.l	D0,-(SP)
	move.w	D6,-(SP)
	move.w	#$40,-(SP)	; - F_WRITE -
	TRAP	#1	; *** GEMDOS ***
	lea	(12,SP),SP
	
	; *** Fermeture du Fichier
	
	move.w	D6,-(SP)
	move.w	#$3E,-(SP)	; - F_CLOSE -
	TRAP	#1	; *** GEMDOS ***
	addq.l	#4,SP
	
	; *** Sortie
	
	clr.w	-(SP)	; - P_TERM0 -
	TRAP	#1	; *** GEMDOS ***
	
	; Et voili, c'est fini, au lit, les petits, sinon guiliguili...
	
; /////////////////////////////////////////////////////////////////////////////	
	; USER SUBROUTINES BANK

; *** Cherche la fin de la Chaine en A0 ***************************************

ZOS_VRSCAN_USTEXT_ENDS:	move.b	(A0)+,D0
	BNE	ZOS_VRSCAN_USTEXT_ENDS

	subq.l	#1,A0
	
ZOS_VRSCAN_USTEXT_SEND:	RTS

; *** Copie de la Chaine A0 en A1 *********************************************
	
ZOS_VRSCAN_USTEXT_SCPY:	move.b	(A0)+,D0
	BEQ	ZOS_VRSCAN_USTEXT_SEND
	
	move.b	D0,(A1)+
	
	BRA	ZOS_VRSCAN_USTEXT_SCPY
	
; *** Copie INVERSE de la Chaine A0 en A1 *************************************
	
ZOS_VRSCAN_USTEXT_RCPY:	movea.l	A0,A2

	BSR	ZOS_VRSCAN_USTEXT_SLEN
	
	subq.w	#1,D0

ZOS_VRSCAN_USTEXT_RLUP:	move.b	(A2,D0.w),(A1)+

	DBF	D0,ZOS_VRSCAN_USTEXT_RLUP
	
	RTS
	
; *** Retourne en D0.w la Longueur de la Chaine en A0 *************************
	
ZOS_VRSCAN_USTEXT_SLEN:	clr.l	D0

ZOS_VRSCAN_USTEXT_LOOP:	tst.b	(D0.w,A0)
	BEQ	ZOS_VRSCAN_USTEXT_SEND
	
	addq.w	#1,D0
	
	BRA	ZOS_VRSCAN_USTEXT_LOOP
	
; *** Convertit un SIGNED WORD en UNSIGNED ASCII DECIMAL **********************
; D0.w : 0 - WORD         A0.l : Adresse du Nombre  
;        1 - LONG
;                         A1.l : Adresse o— mettre le Nombre ASCII

ZOS_VRSCAN_USTEXT_SW2AD: tst.w	D0
	BNE	ZOS_VRSCAN_USTEXT_SWLNG
	
	move.w	(A0),D1
	
	tst.w	D1
	BPL	ZOS_VRSCAN_USTEXT_UW2AD
	
	neg.w	D1
	move.w	D1,(A0)
	move.b	#'-',(A1)+

	BRA	ZOS_VRSCAN_USTEXT_UW2AD
	
ZOS_VRSCAN_USTEXT_SWLNG: move.l	(A0),D1	; LONG

	tst.l	D1
	BPL	ZOS_VRSCAN_USTEXT_UW2AD
	
	neg.l	D1
	move.l	D1,(A0)
	move.b	#'-',(A1)+

; *** Convertit un UNSIGNED WORD en UNSIGNED ASCII DECIMAL ********************
; D0.w : 0 - WORD         A0.l : Adresse du Nombre  
;        1 - LONG
;                         A1.l : Adresse o— mettre le Nombre ASCII

ZOS_VRSCAN_USTEXT_UW2AD: tst.w	D0
	BNE	ZOS_VRSCAN_USTEXT_UWLNG
	
	clr.l	D0
	move.w	(A0),D0	; WORD
	
	BRA	ZOS_VRSCAN_USTEXT_UWNXT
	
ZOS_VRSCAN_USTEXT_UWLNG: move.l	(A0),D0	; LONG

ZOS_VRSCAN_USTEXT_UWNXT: lea	ZOS_VRSCAN_BSS_TKRNUMB,A2

ZOS_VRSCAN_USTEXT_UWLUP: clr.l	D1	; On efface pour le calcul suivant
		
	divu.l	#10,D1:D0	; En D1, le Reste (unit‚)
			; En D0, le Quotient
	
	cmpi.l	#10,D0	; On arrive … la fin?
	BLT	ZOS_VRSCAN_USTEXT_UWLD
	
	add.b	#'0',D1
	move.b	D1,(A2)+	; On place le Reste
	
	BRA	ZOS_VRSCAN_USTEXT_UWLUP
	
ZOS_VRSCAN_USTEXT_UWLD:	tst.b	D0
	BEQ	ZOS_VRSCAN_USTEXT_UWEQ

	add.b	#'0',D0

ZOS_VRSCAN_USTEXT_UWEQ:	add.b	#'0',D1
	move.b	D1,(A2)+	; On place la derniŠre unit‚e
	move.b	D0,(A2)+	; On place la derniŠre dizaine en d‚but
	
	clr.b	(A2)
	
	lea	ZOS_VRSCAN_BSS_TKRNUMB,A0
	
	BSR	ZOS_VRSCAN_USTEXT_RCPY
	
	RTS

; *** Convertit un BINARY WORD en ASCII BINARY ********************************
; D0.w : 0 - WORD         A0.l : Adresse du Nombre  
;        1 - LONG
; D1.w : x - NBBITS       A1.l : Adresse o— mettre le Nombre ASCII

ZOS_VRSCAN_USTEXT_BW2AB: clr.l	D2
	
	tst.w	D0
	BNE	ZOS_VRSCAN_USTEXT_BWLNG
	
	move.w	(A0),D2	; WORD
	
	BRA	ZOS_VRSCAN_USTEXT_BWNXT
	
ZOS_VRSCAN_USTEXT_BWLNG move.l	(A0),D2
	
ZOS_VRSCAN_USTEXT_BWNXT: subq.w	#1,D1	; NBBITS / DBF

	lea	ZOS_VRSCAN_BSS_TKRNUMB,A2
	
ZOS_VRSCAN_USTEXT_BWLUP: btst.l	D1,D2
	BEQ	ZOS_VRSCAN_USTEXT_BWEQ
	
	move.b	#'1',(A2)+
	
	BRA	ZOS_VRSCAN_USTEXT_BWNL
	
ZOS_VRSCAN_USTEXT_BWEQ:	move.b	#'0',(A2)+
	
ZOS_VRSCAN_USTEXT_BWNL:	DBF	D1,ZOS_VRSCAN_USTEXT_BWLUP
	
	clr.b	(A2)
	
	move.l	#ZOS_VRSCAN_BSS_TKRNUMB,A0
	move.b	#'%',(A1)+
	
	BSR	ZOS_VRSCAN_USTEXT_SCPY
	
	RTS

; *** Teste la limite 512, et retranche en fonction ***************************
; D0.w : 0 - WORD         A0.l : Adresse du Nombre  
;
;                         A1.l : Adresse o— mettre le Nombre ASCII

ZOS_VRSCAN_USTEXT_T512D: move.w	(A0),D1
	cmpi.w	#512,D1
	BLT	ZOS_VRSCAN_USTEXT_TSUB
	
	subi.w	#512,D1
	move.w	D1,(A0)
	
	move.l	#'HS. ',(A1)+
	
ZOS_VRSCAN_USTEXT_TSUB:	BSR	ZOS_VRSCAN_USTEXT_UW2AD

	RTS

; *** MATH SUB le Nombre A1 … A0 **********************************************
; D0.w : 0 - WORD         A0.l : Adresse du Nombre A 
;                         A1.l : Adresse o— mettre le Nombre ASCII
;                         A2.l : Adresse du Nombre B

ZOS_VRSCAN_USTEXT_MATHX: lea	ZOS_VRSCAN_BSS_TEMPONUM,A3

	move.w	(A0),D0
	sub.w	(A2),D0
	
	move.w	D0,(A3)
	movea.l	A3,A0
	
	clr.w	D0
	BSR	ZOS_VRSCAN_USTEXT_SW2AD

	RTS

; *** ASCII Insertion *********************************************************
; D0.w : ASCII
;
;                         A1.l : Adresse o— mettre le Char ASCII

ZOS_VRSCAN_USTEXT_ASCII: move.b	#' ',(A1)+
	move.b	D0,(A1)+
	move.b	#' ',(A1)+

	RTS

; *** Chargement 2 ************************************************************

ZOS_VRSCAN_USTEXT_LOAD2: move.w	(A6)+,D0

	RTS

; *** Chargement 3 ************************************************************

ZOS_VRSCAN_USTEXT_LOAD3: move.w	(A6)+,D0
	movea.l	(A6)+,A0

	RTS

; *** Chargement 4 ************************************************************

ZOS_VRSCAN_USTEXT_LOAD4: move.w	(A6)+,D0
	move.w	(A6)+,D1
	movea.l	(A6)+,A0

	RTS

; *** Chargement 5 ************************************************************

ZOS_VRSCAN_USTEXT_LOAD5: move.w	(A6)+,D0
	movea.l	(A6)+,A0
	movea.l	(A6)+,A2

	RTS
	
; /////////////////////////////////////////////////////////////////////////////	
	; SUPERVISOR SUBROUTINES BANK

; *** Lit ce qu'a le VIDEL dans le ventre - SUPERVISEUR ***********************
	
ZOS_VRSCAN_SSTEXT_VREAD: move.w	$FFFF820E.w,ZOS_VRSCAN_BSS_OSTNL
	move.w	$FFFF8210.w,ZOS_VRSCAN_BSS_VWRAP
	move.b	$FFFF8260.w,ZOS_VRSCAN_BSS_STSHIFT
	move.b	$FFFF8265.w,ZOS_VRSCAN_BSS_HSR
	move.w	$FFFF8266.w,ZOS_VRSCAN_BSS_SPSHIFT
	move.w	$FFFF8282.w,ZOS_VRSCAN_BSS_HHT
	move.w	$FFFF8284.w,ZOS_VRSCAN_BSS_HBB
	move.w	$FFFF8286.w,ZOS_VRSCAN_BSS_HBE
	move.w	$FFFF8288.w,ZOS_VRSCAN_BSS_HDB
	move.w	$FFFF828A.w,ZOS_VRSCAN_BSS_HDE
	move.w	$FFFF828C.w,ZOS_VRSCAN_BSS_HSS
	move.w	$FFFF828E.w,ZOS_VRSCAN_BSS_HFS
	move.w	$FFFF8290.w,ZOS_VRSCAN_BSS_HEE
	move.w	$FFFF82A2.w,ZOS_VRSCAN_BSS_VFT
	move.w	$FFFF82A4.w,ZOS_VRSCAN_BSS_VBB
	move.w	$FFFF82A6.w,ZOS_VRSCAN_BSS_VBE
	move.w	$FFFF82A8.w,ZOS_VRSCAN_BSS_VDB
	move.w	$FFFF82AA.w,ZOS_VRSCAN_BSS_VDE
	move.w	$FFFF82AC.w,ZOS_VRSCAN_BSS_VSS
	move.w	$FFFF82C0.w,ZOS_VRSCAN_BSS_RCO
	move.w	$FFFF82C2.w,ZOS_VRSCAN_BSS_VCO

	RTS

; /////////////////////////////////////////////////////////////////////////////	
	SECTION	DATA
; /////////////////////////////////////////////////////////////////////////////	

ZOS_VRSCAN_DATA_HEADR1:	dc.b	'| R‚solution ',0
ZOS_VRSCAN_DATA_HEADR2:	dc.b	' | H Rez - V Rez - V Plan - '
	dc.b	'L Size - S Size | OSTNL - VWRAP - '
	dc.b	'STSHIFT %ST - SPSHIFT %COCxHVCBANK - HSR | '
	dc.b	' HBE -  HDB -  HDE -  HBB -  HSS -  HHT + '
	dc.b	'HFS - HEE + (HDB - HBE) / (HDE - HDB) / '
	dc.b	'(HBB - HDE) / (HBB - HBE) / '
	dc.b	'(HHT - HSS) |  VBE -  VDB -  VDE -  VBB - '
	dc.b	' VSS -  VFT + (VDB - VBE) / (VDE - VDB) / '
	dc.b	'(VBB - VDE) / (VBB - VBE) / (VFT - VSS) | '
	dc.b	'RCO %OBHVxICMT - VCO %PWID |',13,10

	dc.b	'+--------------'
	dc.b	'-+--------------------------'
	dc.b	'----------------+-----------------'
	dc.b	'-----------------------------------------+-'
	dc.b	'------------------------------------------'
	dc.b	'----------------------------------------'
	dc.b	'----------------------------'
	dc.b	'------------+-----------------------------'
	dc.b	'------------------------------------------'
	dc.b	'----------------------------------------+-'
	dc.b	'---------------------------+',13,10,0

ZOS_VRSCAN_DATA_M0TXT:	dc.b	'MONO\',0
ZOS_VRSCAN_DATA_M1TXT:	dc.b	'RGB\',0
ZOS_VRSCAN_DATA_M2TXT:	dc.b	'VGA\',0
ZOS_VRSCAN_DATA_M3TXT:	dc.b	'TV\',0
	
ZOS_VRSCAN_DATA_MONTAB:	dc.l	ZOS_VRSCAN_DATA_M0TXT
	dc.l	ZOS_VRSCAN_DATA_M1TXT
	dc.l	ZOS_VRSCAN_DATA_M2TXT
	dc.l	ZOS_VRSCAN_DATA_M3TXT
	
ZOS_VRSCAN_DATA_CNVTAB:	dc.l	ZOS_VRSCAN_USTEXT_SW2AD
	dc.l	ZOS_VRSCAN_USTEXT_UW2AD
	dc.l	ZOS_VRSCAN_USTEXT_BW2AB
	dc.l	ZOS_VRSCAN_USTEXT_T512D
	dc.l	ZOS_VRSCAN_USTEXT_MATHX
	dc.l	ZOS_VRSCAN_USTEXT_ASCII

ZOS_VRSCAN_DATA_LDTAB:	dc.l	ZOS_VRSCAN_USTEXT_LOAD3
	dc.l	ZOS_VRSCAN_USTEXT_LOAD3
	dc.l	ZOS_VRSCAN_USTEXT_LOAD4
	dc.l	ZOS_VRSCAN_USTEXT_LOAD3
	dc.l	ZOS_VRSCAN_USTEXT_LOAD5
	dc.l	ZOS_VRSCAN_USTEXT_LOAD2

	; 0 : SW2AD
	;     0 : WORD
	;     1 : LONG
	; 1 : UW2AD
	;     0 : WORD
	;     1 : LONG
	; 2 : BW2AB
	;     0 : WORD
	;     1 : LONG
	;
	;     x : NBBITS
	; 3 : TEST 512 UW2AD
	;     0 : WORD
	; 4 : MATH SUB (A-B) -> SW2AD
	;     0 : WORD
	; 5 : ASCII Insert
	;     x : Char
	; 6 : END

ZOS_VRSCAN_DATA_REGTAB:	dc.w	5,'|'

	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_LAHR
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_LAVR
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_LAPR
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_LALS
	dc.w	5,'-'
	dc.w	1,1
	dc.l	ZOS_VRSCAN_BSS_SSIZ

	dc.w	5,'|'

	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_OSTNL
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_VWRAP
	dc.w	5,'-'
	dc.w	2,0,2
	dc.l	ZOS_VRSCAN_BSS_preSTSHIFT
	dc.w	5,'-'
	dc.w	2,0,11
	dc.l	ZOS_VRSCAN_BSS_SPSHIFT
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_preHSR

	dc.w	5,'|'

	dc.w	3,0
	dc.l	ZOS_VRSCAN_BSS_HBE
	dc.w	5,'-'
	dc.w	3,0
	dc.l	ZOS_VRSCAN_BSS_HDB
	dc.w	5,'-'
	dc.w	3,0
	dc.l	ZOS_VRSCAN_BSS_HDE
	dc.w	5,'-'
	dc.w	3,0
	dc.l	ZOS_VRSCAN_BSS_HBB
	dc.w	5,'-'
	dc.w	3,0
	dc.l	ZOS_VRSCAN_BSS_HSS
	dc.w	5,'-'
	dc.w	3,0
	dc.l	ZOS_VRSCAN_BSS_HHT
	dc.w	5,'+'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_HFS
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_HEE
	dc.w	5,'+'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_HDB
	dc.l	ZOS_VRSCAN_BSS_HBE
	dc.w	5,'/'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_HDE
	dc.l	ZOS_VRSCAN_BSS_HDB
	dc.w	5,'/'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_HBB
	dc.l	ZOS_VRSCAN_BSS_HDE
	dc.w	5,'/'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_HBB
	dc.l	ZOS_VRSCAN_BSS_HBE
	dc.w	5,'/'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_HHT
	dc.l	ZOS_VRSCAN_BSS_HSS
	
	dc.w	5,'|'

	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_VBE
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_VDB
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_VDE
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_VBB
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_VSS
	dc.w	5,'-'
	dc.w	1,0
	dc.l	ZOS_VRSCAN_BSS_VFT
	dc.w	5,'+'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_VDB
	dc.l	ZOS_VRSCAN_BSS_VBE
	dc.w	5,'/'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_VDE
	dc.l	ZOS_VRSCAN_BSS_VDB
	dc.w	5,'/'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_VBB
	dc.l	ZOS_VRSCAN_BSS_VDE
	dc.w	5,'/'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_VBB
	dc.l	ZOS_VRSCAN_BSS_VBE
	dc.w	5,'/'
	dc.w	4,0
	dc.l	ZOS_VRSCAN_BSS_VFT
	dc.l	ZOS_VRSCAN_BSS_VSS

	dc.w	5,'|'

	dc.w	2,0,9
	dc.l	ZOS_VRSCAN_BSS_RCO
	dc.w	5,'-'
	dc.w	2,0,4
	dc.l	ZOS_VRSCAN_BSS_VCO

	dc.w	5,'|'
	
	dc.w	6,0

; /////////////////////////////////////////////////////////////////////////////	
	SECTION	BSS
; /////////////////////////////////////////////////////////////////////////////	

ZOS_VRSCAN_BSS_LAHR:	ds.w	1
ZOS_VRSCAN_BSS_LAVR:	ds.w	1
ZOS_VRSCAN_BSS_LAPR:	ds.w	1
ZOS_VRSCAN_BSS_LALS:	ds.w	1
ZOS_VRSCAN_BSS_SSIZ:	ds.l	1

ZOS_VRSCAN_BSS_OSTNL:	ds.w	1
ZOS_VRSCAN_BSS_VWRAP:	ds.w	1
ZOS_VRSCAN_BSS_preSTSHIFT: ds.b	1
ZOS_VRSCAN_BSS_STSHIFT:	ds.b	1
ZOS_VRSCAN_BSS_preHSR:	ds.b	1
ZOS_VRSCAN_BSS_HSR:	ds.b	1
ZOS_VRSCAN_BSS_SPSHIFT:	ds.w	1
ZOS_VRSCAN_BSS_HHT:	ds.w	1
ZOS_VRSCAN_BSS_HSS:	ds.w	1
ZOS_VRSCAN_BSS_HBE:	ds.w	1
ZOS_VRSCAN_BSS_HDB:	ds.w	1
ZOS_VRSCAN_BSS_HDE:	ds.w	1
ZOS_VRSCAN_BSS_HBB:	ds.w	1
ZOS_VRSCAN_BSS_HFS:	ds.w	1
ZOS_VRSCAN_BSS_HEE:	ds.w	1
ZOS_VRSCAN_BSS_VFT:	ds.w	1
ZOS_VRSCAN_BSS_VSS:	ds.w	1
ZOS_VRSCAN_BSS_VBE:	ds.w	1
ZOS_VRSCAN_BSS_VDB:	ds.w	1
ZOS_VRSCAN_BSS_VDE:	ds.w	1
ZOS_VRSCAN_BSS_VBB:	ds.w	1
ZOS_VRSCAN_BSS_RCO:	ds.w	1
ZOS_VRSCAN_BSS_VCO:	ds.w	1

ZOS_VRSCAN_BSS_TEMPONUM: ds.w	1
ZOS_VRSCAN_BSS_TKRNUMB:	ds.b	64

ZOS_VRSCAN_BSS_FILEN:	ds.b	16
ZOS_VRSCAN_BSS_FILET:	ds.b	16
ZOS_VRSCAN_BSS_FILEP:	ds.b	256
ZOS_VRSCAN_BSS_FILED:	ds.b	8192