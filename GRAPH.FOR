C **************************************
C *                                    *
C * GRAPH                              *
C *                                    *
C * PLOT A GRAPH WITH AXES, USING      *
C * A SINGLE DIMENSIONAL ARRAY AND     *
C * DO LOOPS.                          *
C *                                    *
C * WRITTEN IN SUBSET FORTRAN 77       *
C * ( FORTRAN IV WITH SOME LIMITED     *
C *   FORTRAN 77 FEATURES )            *
C *                                    *
C * COMPILED WITH MICROSOFT FORTRAN    *
C * COMPILER VERSION 3.31              *
C *                                    *
C * MICKEY LAWLESS                     *
C *                                    *
C **************************************

	PROGRAM GRAPH

	INTEGER VLINE( 65 ), INDEX, K1, LIMIT,
     >        Y, DASH, EYE, SPACE, STAR
	DATA DASH/'-'/ EYE/'I'/ SPACE/' '/ STAR/'*'/
	IFUNCT( Y ) = Y**2

C * SETUP PRINTING THE Y-AXIS LABELS

	DO 10 INDEX = 1, 6
	   VLINE( INDEX ) = 10 * ( INDEX - 1 )
10      CONTINUE

C * WRITE OUT THE NUMERIC LABELS

	WRITE(*,22) ( VLINE( K1 ),K1 = 1, 6 )
22      FORMAT(' ', 6( 8X, I2 ) )

C * SETUP THE Y-AXIS ITSELF

	DO 30 INDEX = 1, 65
	   VLINE( INDEX ) = DASH
30      CONTINUE
	DO 40 INDEX = 10, 60, 10
	   VLINE( INDEX ) = EYE
40      CONTINUE

C * WRITE OUT THE Y-AXIS

	WRITE(*,902) VLINE

C * NOW BEGIN PLOTTING POINTS ON GRAPH

	DO 60 INDEX = 1, 15
	   DO 50 K1 = 1, 65
	      VLINE( K1 ) = SPACE
50         CONTINUE
	   VLINE( 10 ) = EYE

C * VLINE CONTAINS SPACES AND I FOR X-AXIS

	   Y = IFUNCT( INDEX - 8 ) + 10

C * LOAD STAR FOR PLOTTED POINT FROM DATA

	   VLINE( Y ) = STAR
	   LIMIT = MAX0( 10, Y )
	   WRITE(*,902) ( VLINE( K1 ), K1 = 1, LIMIT )
60      CONTINUE
902     FORMAT( ' ', 65A1 )

	END
