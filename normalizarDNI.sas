/*
T ---> 0
....
E ---> 22

Al llegar un número de DNI, calcular el resto de la división 
entera entre 23... Eso va a dar un número entre 0 y 22.
La letra del DNI será la asociada a ese Número.

SAS Permite calcular el resto de la división entera:
La función que lo hace es la función: MOD
*/
DATA LETRAS_DNI;
INPUT LETRA $;
CARDS;
T 
R
W
A
G
M
Y
F
P
D
X
B
N
J
Z
S
Q
V
H
L
C
K
E
;
RUN;

DATA LETRAS_DNI;
SET LETRAS_DNI;
/*RETAIN RESTO (-1);
RESTO=RESTO+1;*/
RESTO=_N_-1; /* _N_ es el número de observación de cada fila, 
			    dentro de un paso data*/
RUN;

/*
Número de DNI: 23000000
Resto al dividir entre 23: 0
	DATA MI_LETRA;
	SET LETRAS_DNI;
	WHERE RESTO=0;
	RUN;
*/
/* 
Las variables en SAS tienen un SCOPE: Ambito 
El ámbito de una variable es el lugar donde se puede utilizar.
Por defecto, al crear una variable dentro de una macro, 
la variable sólo puede ser utilizada dentro de esa macro.
A la hora de definir una variable, podemos utiliza 2 palabras diferentes:
	%local: Es la opcion por defecto, si no pongo nada explicitamente
	%global: Hay que declararlo explicitamente

Con %local, una variable solo vive allí donde ha sido definida. 
Ese es su scope.
Con %global, una variable puede ser utilizada en cualquier sitio.

Para crear una variable, hemos usado %let, pero realmente no es la palabra 
adecuada para crear una variable. La palabra %let, sólo debería utilizarse para
asignar valor a una variable. Lo mismo aplica a la palabra "call symput".
Si una variable se inetnta asignar y no existe, SAS por defecto, la define con 
la palabra %local.
*/
%macro LetraDNI(numero_dni);
	%local resto;      /* Solo podrá utilizarse desde la propia macro */
	%global letra_dni; /* Podrá utilizarse en cualquier sitio */

	%let resto=%sysfunc(mod(&numero_dni,23));

	/* El nombre _null_ le indica a SAS Que tire el DATA a la basura*/
	DATA _null_;  
		SET LETRAS_DNI;
		WHERE RESTO=&resto;
		/* Generamos una variable llamada letra_dni, cuyo contenido es el valor de
		la columna LETRA */
		call symput("letra_dni", LETRA);
	RUN;

	/*%put La letra asociada es: &letra_dni;*/

%mend;
/*
%LetraDNI(23000000);
%put La letra asociada es: &letra_dni;
*/
%macro normalizarDNI(dni, ceros=0, separador_miles=0, separador_letra_control=);
	/********************************************
	**   DEFINIR LAS VARIABLES DE LA FUNCION
	********************************************/
	%local letra;
	%local longitud_dni;
	%local separador;
	/*local numero_en_bruto;*/
	%local total_de_caracteres_del_numero;
	%local cuantos_llevo;
	%local viene_con_puntos;
	%local numero_limpio;
	%global dni_formateado;

	/********************************************
	**   PREPROCESAR LOS DATOS
	********************************************/
	%let dni=%sysfunc(trim(&dni)); /*Quitar los espacios en blanco*/
	%let longitud_dni=%length(&dni);
	/*Si me han pasado un DNI vacio => ERROR !*/
	%if &longitud_dni=0 %then %do;
		%put ERROR: El dni suministrado está vacio.;
		%return; /* Salirse de la macro y ya no sigue ejecutando */
	%end;

	/********************************************
	**   PROCESAR LA LETRA
	********************************************/
	%let letra=%upcase(%substr(&dni,&longitud_dni,1));
	%if %sysfunc(anydigit(&letra))>0 %then %do; /* Es un digito... No hay letra de control*/
		%put ERROR: El dni suministrado (&dni) no tiene dígito de control.;
		%return;
	%end;
	/* Si he llegado hasta aquí, es que tengo un dni con letra de control al final */

	/********************************************
	**   PROCESAR EL SEPARADOR
	********************************************/
	%if &longitud_dni=1 %then %do;
		%put ERROR: El dni suministrado (&dni) no contiene digitos.;
		%return; /* Salirse de la macro y ya no sigue ejecutando */
	%end;

	%let separador=%substr(&dni,&longitud_dni-1,1);
	%if %sysfunc(anydigit(%str(&separador)))>0 %then %do; 
		/* No tengo separador*/
		%let total_de_caracteres_del_numero=%eval(&longitud_dni-1);
	%end;
	%else %do;
		%if "&separador"="-" or "&separador"="" %then %do;
			/* Tengo un separador válido */
			%let total_de_caracteres_del_numero=%eval(&longitud_dni-2);
		%end;
		%else %do;
			/* Tengo un separador inválido*/
			%put ERROR: El dni suministrado (&dni) utiliza un separador inválido.;
			%return;
		%end;
	%end;

	/********************************************
	**   PROCESAR EL NUMERO
	********************************************/
	/*
			Numero en bruto:   65.476.473
			Posicion     10  -> 3     Cuantos llevo= 1
			Posicion     9  --> 7     Cuantos llevo= 2
			Posicion     8  --> 4     Cuantos llevo= 3
			Posicion     7  --> .     Cuantos llevo= 4 <<<<<<
			Posicion     6  --> 6     Cuantos llevo= 5
			Posicion     5  --> 7     Cuantos llevo= 6
			Posicion     4  --> 4     Cuantos llevo= 7
			Posicion     3  --> .     Cuantos llevo= 8 <<<<<<
			Posicion     2  --> 5     Cuantos llevo= 9
			Posicion     1  --> 6     Cuantos llevo= 10

			Numero en bruto:   5.476.473
			Posicion     9  --> 3     Cuantos llevo= 1
			Posicion     8  --> 7     Cuantos llevo= 2
			Posicion     7  --> 4     Cuantos llevo= 3	
			Posicion     6  --> .     Cuantos llevo= 4 <<<<<<
			Posicion     5  --> 6     Cuantos llevo= 5	
			Posicion     4  --> 7     Cuantos llevo= 6
			Posicion     3  --> 4     Cuantos llevo= 7	
			Posicion     2  --> .     Cuantos llevo= 8 <<<<<<
			Posicion     1  --> 5     Cuantos llevo= 9	

	%let numero_en_bruto=%substr(&dni, 1, &total_de_caracteres_del_numero );
	*/
	%let cuantos_llevo=0;
	%let viene_con_puntos=0; /* Presupongo que no viene con puntos */ 
	%do posicion=&total_de_caracteres_del_numero %to 1 %by -1;
		%let caracter_actual=%substr(&dni,&posicion,1);
		%let cuantos_llevo=%eval(&cuantos_llevo+1);

		/* Mirar si un determinado caracter es un dígito*/
		%if %sysfunc(anydigit(&caracter_actual))>0 %then %do; 
			/*Es un digito*/
			%if &viene_con_puntos=1 %then %do;
				%if &cuantos_llevo=8 %then %do;
					/* El dígito no está OK */
					%put ERROR: Al dni suministrado (&dni) le falta el separador de millones.;
					%return;
				%end;
			%end;
			%let numero_limpio=&caracter_actual&numero_limpio;
		%end;
		/* Mirar si un determinado caracter es un punto*/
		%else %if "&caracter_actual"="." %then %do;
			%if &cuantos_llevo=4 %then %do;
				/* El punto está OK */
				%let viene_con_puntos=1; /* Si que viene con puntos */
			%end;
			%else %if &cuantos_llevo=8 %then %do;
				%if &viene_con_puntos=0 %then %do;
					/* El punto no está OK */
					%put ERROR: Al dni suministrado (&dni) le falta el separador de miles.;
					%return;
				%end;
			%end;
			%else %do;
				%put ERROR: El dni suministrado (&dni) tienen los separadores de miles mal colocados.;
				%return;
			%end;
		%end;
		/* No es ni un dígito, ni un punto */
		%else %do;
			%put ERROR: El dni suministrado (&dni) presenta un carácter incorrecto: &caracter_actual.;
			%return;
		%end;
	%end; /*Este es en end del do, del bucle*/ 

	/* El primer caracter no puede ser un punto*/
	%if %substr(&dni,1,1)=. %then %do;
		%put ERROR: El dni suministrado (&dni) no puede comenzar con un punto.;
		%return;
	%end;

	/* Comprobar el numero que no sea muy grande */
	%if %length(&numero_limpio)>8 %then %do;
		%put ERROR: El dni suministrado (&dni) tiene demasiadas cifras.;
		%return;
	%end;
	/* Comprobar que la letra es correcta */
	%LetraDNI(&numero_limpio);
	%if &letra_dni~=&letra %then %do;
		%put ERROR: La letra de control del dni suministrado (&dni) no coincide.;
		%return;
	%end;
	/*
		Llegados a este punto:
			- Tengo un DNI válido
			- Tengo la letra del DNI: &letra
			- Tengo el número limpio del DNI: &numero_limpio
	*/
	/*%let numero_limpio=%eval(&numero_limpio*1);*/
	%let numero_limpio=%sysfunc(inputn(&numero_limpio,8.));

	/**************************************************************
	***       Formatear el DNI
	**************************************************************/
	/*
		- Generar el número formateado
			- Partimos del numero_limpio
			- Que le ponga ceros o no
			- Que le ponga puntos o no
		23000 >>>> 00023000 >>>> 00.023.000
		00000001
		000000011
		0000000111
		00000001111
		000000011111
		000000011111111
		- Concatenar numero_formateado y separador(el que me den) y letra
	*/
	%let dni_formateado=&numero_limpio;
	%if &ceros~=0 %then %do;
		%let dni_formateado=0000000&dni_formateado;
		%let dni_formateado=%substr(&dni_formateado,%length(&numero_limpio),8);
	%end;

	%if &separador_miles~=0 %then %do;
		%if %length(&dni_formateado)>3 %then %do;
			/* 1.234 >>> 1.234 
				Longitud: 4
				1->1
				2->3
		       12.345
				Longitud: 5
				Desde la posición 1-> Tomo 2 caracteres:   12
				Desde la posición 3-> Tomo 3 caracteres:  345
			   1234.567
				Longitud: 7
				Desde la posición 1-> Tomo 4 caracteres:   1234
				Desde la posición 5-> Tomo 3 caracteres:  567
			   02300000
				Longitud: 8
				Desde la posición 1  > Toma 5 caracteres    2300
				Desde la posicion 5  > Toma 3 caracteres
			*/
			%let dni_formateado=%substr(&dni_formateado,1,%length(&dni_formateado)-3).%substr(&dni_formateado,%length(&dni_formateado)-2,3);
		%end;
		%if %length(&dni_formateado)>7 %then %do;
			/* 1234.567
				Longitud: 8
				Desde la posición 1-> Tomo 1 caracteres:   1
				Desde la posición 2-> Tomo 7 caracteres:  234.567
			   01234.567
				Longitud: 9
				Desde la posición 1-> Tomo 2 caracteres:   01
				Desde la posición 2-> Tomo 7 caracteres:  234.567
			*/
			%let dni_formateado=%substr(&dni_formateado,1,%length(&dni_formateado)-7).%substr(&dni_formateado,%length(&dni_formateado)-6,7);
		%end;
	%end;
	/* Concatenar el separador y la letra */
	%let dni_formateado=&dni_formateado&separador_letra_control&letra;

	/*%put El DNI Normalizado es: &dni_formateado;*/
%mend normalizarDNI;

/*
Como validar el DNI... Que REGLAS debe cumplir un DNI
- La última debe ser una letra
- La antepenúltima debe ser un número o un guión o un espacio
- El resto de caracteres deben ser números... todos?
		- Con la excepción de los puntos... si aparecen:
			- En la cuarta posicion empezando por la derecha
			- Y en la octava... siempre?
					- Cuando exista octava posicion
					- Que antes haya numeros
					- Que exista un punto en la cuarta
*/
/* La función trim(texto), devuelve el texto, sin los espacios en blanco
que haya por delante y por detras*/
%normalizarDNI(    23.000.000-t );  
%put DNI Normalizado= &dni_formateado; 
/*
%normalizarDNI(    17236482647323.000.000-t );
%normalizarDNI(23000.000T);
%normalizarDNI(%str(23000000=T));
%normalizarDNI(%str(23000000 t));
%normalizarDNI(23000000-T); 
%normalizarDNI(.000.000t);
%normalizarDNI(2j00000t);   
%normalizarDNI(02300000t);  
%normalizarDNI(02.300.000T);
%normalizarDNI(121.015F);
%normalizarDNI(00.001.015F);
%normalizarDNI(.015f);
%normalizarDNI(15S);
%normalizarDNI(02.300.000);
%normalizarDNI(A02.300.000);
%normalizarDNI(02.300000T);
%normalizarDNI(02.300.000T, ceros=1, separador_letra_control=., separador_miles=1);
%normalizarDNI(02.300.000T, ceros=1, separador_letra_control=, separador_miles=0);
%normalizarDNI(02.300.000T, ceros=0, separador_letra_control=%str(-), separador_miles=0);
%normalizarDNI(Croasan);
*/
/*
1º Validar que el DNI sea correcto
	----> Si es correcto, haber extraido:
				el número 
				la letra
2º Si es correcto, debe normalizarlo: 02300000T
3º Si no es correcto, informaré los motivos
*/

/*
DataSet que tiene 4 millones de DNIs
	23000T         >>>>>  00023000T
Cruzar ese dataset con otro datase que ha mandado un proveedor
en el cual los DNIs están escritos de forma diferente
	00.023.000-t   >>>>>  00023000T
		numero_limpio: 23000 >>> 00023000
	00.023.000     >>>>>       23000
	00.023.000     >>>>>    00023000
	23.000     	   >>>>>       23000
	23.000         >>>>>    00023000
	023.000        >>>>>    00023000
	023.000        >>>>>       23000 <<< ERROR
*/


/*
23.123.123-T

1º Verificar que no está vacio
2º Tomar el ultimo caracter y verificar que es una letra 
	>>> LO GUARDA EN LA VARIABLE LETRA
3º Mirar el penultimo caracter
	- Que sea un guion o un espacio, OK
	- Que sea un número, OK
	- No es un guion o un espacio o un número >>> ERROR
4º Procesar la parte del número
	De donde a donde va esa parte???
		Del primero al ???
			Si no tiene separador, al penultimo
			Si tiene separador, al antepenultimo
	23.123.123 >>> numero_en_bruto
	Analizamos el numero en bruto:
		Revisar caracter a caracter, empezando por la derecha
			- Que sea un número
				- Miro si debería ser un número.
					Si vengo usando puntos (es decir, si el cuarto ha sido un punto)
					entonces el 8 no deberia ser un numero >>>> ERROR
				- Si si que deberia ser un numero >>> OK
						GUARDO LOS NUMEROS!!!!
			- Que sea un punto: Miro si aparece en las posiciones correctas
				- NO >>>> ERROR
				- SI >>> OK
			- Que sea otra cosa >>>> ERROR
	numro_limpio=3	
	numro_limpio=2 + numerp_limpio	= 23
	numro_limpio=1 + numerp_limpio	= 123

*/
