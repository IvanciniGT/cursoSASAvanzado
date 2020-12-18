/********************************************
**      Comunidades
********************************************/
DATA comunidades;
	INFILE '/home/cursoloyal10/SAS_Base_I/Ficheros/comunidades.txt';
	INPUT id 1-2 comunidad $ 3-36 ventas 37-46;
RUN;

DATA DATOS_FORMATO_COMUNIDADES;
	SET WORK.comunidades;
	DROP ventas; /* Esto elimina un campo */
	RENAME id=Start;
	RENAME comunidad=Label;
	fmtname="NOMBRE_COMUNIDADES";
	type="N";
RUN;

/* Crear un formato, pero a partir de unos datos que
tenemos en una tabla de datos */
PROC FORMAT CNTLIN=DATOS_FORMATO_COMUNIDADES;

PROC SORT data=comunidades; 
	BY Ventas;

/* Preparación de los datos de comunidades */
DATA comunidades;
	SET WORK.comunidades;
	RETAIN MINIMO;
	if _N_=1 THEN MINIMO=Ventas;    /* Retenemos el mínimo */
	PESO=Ventas/minimo;             /* Calculamos un peso */
	FORMAT id NOMBRE_COMUNIDADES.;  /* Aplicamos el formato */
	DROP comunidad minimo;
RUN;

/********************************************
**      Clientes
********************************************/
PROC IMPORT DATAFILE='/home/cursoloyal10/SAS_Base_I/Ficheros/clientes.xls'
	DBMS=XLS OUT=clientes REPLACE;
RUN;

/*
Problema columna sexo.
	Querria tener 2 valores:
		1 Mujer
		2 Hombre
Solución mediante Formatos: NO ES LA MEJOR :(
Más abajo damos una solución automatizada para este problema.
	Entrada  >>>> Informat 
		Establace cómo se debe leer algo, para guardarlo
		en SAS de otra forma distinta.
	Salida   >>>> Format
		Establece cómo se debe mostrar algo, que está
		guardado en SAS de una forma distinta.
*/


/* Creamos nuestrio primer formato */
PROC FORMAT ;
value GENEROS
	1 = "Mujer"	
	2 = "Hombre";
invalue GENEROS
	"Mujer"	    = 1
	"Muujer"	= 1
	"Mujeer"	= 1
	"Chica"	    = 1
	"Hombre"    = 2
	"Hoombre"   = 2
	"Hombree"   = 2
	"Varon"     = 2
	"Chico"     = 2;
RUN;

DATA clientes_preprocesado;
	SET clientes;
	genero=INPUT(sexo,GENEROS.);         /* Aplicamos un formato de entrada */
	FORMAT genero GENEROS.;              /* Aplicacos un formato de salida */
RUN;

/* 
Esta solución es difilmente mantenible...
Vamos a tratar de automatizar el proceso de identificación de nuevos géneros.
	Leer el fichero de clientes.
	Obtener TODOS los valores diferentes que hay en SEXO.
	Darle un número a cada valor. <<<< MANUAL
		De los NUEVOS que PREVIAMENTE no tenga registrados.
				Necesito una tabla donde voy a ir dejando los valores de ejecuciones pasadas.
	CODIFICAR los generos según los valores anteriores.
*/
/* Quiero sacar todos los valores distintos del SEXO*/
PROC FREQ data=clientes;
	TABLE sexo / OUT=sexos_actuales (keep=sexo);
/*
sexo
--------
Mijer
Mujer
Hombre
Chavalote
...
*/

/* Voy a crearme una tabla inicial */
%macro generarCodigos(); 
%put Voy a ver si hace falta generar la tabla inicial de generos;
%if ~%sysfunc(exist(CODIGOS_GENERO)) %then %do;
%put Generando tabla inicial;
DATA CODIGOS_GENERO;
LENGTH genero $ 10;
id=1;
genero='Mujer';
output;
id=2;
genero='Hombre';
output;
RUN;
%end;
%mend generarCodigos;
%generarCodigos();


/* Quiero sacar los datos de la tabla SEXOS_ACTUALES que no están en CODIGOS_GENERO */
PROC SORT data=codigos_genero; by genero;
PROC SORT data=sexos_actuales; by sexo;
DATA nuevos_generos;
	MERGE 
		sexos_actuales (/*in=estaEnNueva*/ rename=(sexo=genero))
		codigos_genero (in=estaEnAntigua)
		/*Las variables declaras mediante IN, contienen:
			0: Si una fila no proviene de una tabla
			1: Si una fila proviene de una tabla
		NUEVOS      ANTIGUOS     estaEnNueva          estaEnAntigua
		Mijer                         1                     0
		Mujer        Mujer            1                     1
		Hombre       Hombre           1                     1
		Chavalote                     1                     0
		*/
	;
	IF estaEnAntigua=0 THEN; OUTPUT;
	BY genero;
RUN;

/*
DATA _null_; 
	SET nuevos_generos;
	FILE '/home/cursoloyal10/SAS_Base_I/Ficheros/PendientesCodificar.txt' termstr=crlf;
	put @1 id @2 genero;
RUN;
*/

DATA  CODIGOS_GENERO;
SET CODIGOS_GENERO NUEVOS_GENEROS;
RUN;

PROC SORT data=codigos_genero; by genero;
PROC SORT data=sexos_actuales; by sexo;
DATA clientes_preprocesados;
	MERGE 
		clientes (rename=(sexo=genero) in=actual)
		codigos_genero 
	;
	IF actual=1 THEN; OUTPUT;
	BY genero;
	DROP genero;
	FORMAT id GENEROS.;
RUN;
