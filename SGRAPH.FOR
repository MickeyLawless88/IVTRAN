C ***********************************************
C *					                                  	*
C * SGRAPH					                            *
C *						                                  *
C * PRINTS A 3D PLOT OF SURFACE GRAPH FROM USER	*
C * SPECIFIED DATA.				                      *
C *						                                  *
C * MICKEY LAWLESS				                      *
C *						                                  *
C ***********************************************


	PROGRAM SGRAPH
	
	INTEGER HPOS, VPOS, SLICES, N, MAXZ, NSLICE, HORIZ
	REAL XINC, YINC, ZINC, X, Y, Z, F
	PARAMETER( HPOS = 72, VPOS = 50 )
	CHARACTER*( HPOS ) LINE
	LOGICAL FILLED

	PRINT *, 'ENTER NUMBER OF SLICES: '
	READ *, SLICES

C * SET INCREMENTS FOR AXES

	ZINC = NINT( HPOS /( 2. * SLICES ))
	XINC = NINT( .6 * ZINC )
	YINC = SQRT( XINC ** 2 + ZINC ** 2 )

C * PLOT THE SURFACE

	DO 20 N = 0, VPOS + SLICES * XINC
	   
	   LINE = ' '
	   MAXZ = 0
	   NSLICE = 0
	   FILLED = .FALSE.

10	   IF(( NSLICE.LE.SLICES ).AND. .NOT.FILLED ) THEN
	   IF( NSLICE.GT.NINT( N / XINC )) THEN
	   FILLED = .TRUE.
	     ELSE IF ( NSLICE.GE.NINT(( N - VPOS )/ XINC )) THEN
	     HORIZ = NINT( NSLICE * ZINC )

C * CHECK FOR HIDDEN POINT

	     IF( HORIZ.GT.MAXZ ) THEN
	         LINE( HORIZ-1 : HORIZ-1 ) = '.'
               MAXZ = HORIZ
	     END IF

C * DETERMINE WHERE TO PLOT POINT

 	     X = N - NSLICE * XINC
	     Y = NSLICE * YINC
	     Z = F( X,Y )
	     HORIZ = NINT( Z + NSLICE * ZINC )

C * CHECK FOR HIDDEN POINT AGAIN

	     IF( HORIZ.GT.MAXZ ) THEN
	         LINE( HORIZ-1 : HORIZ-1 ) = '*'
               MAXZ = HORIZ
	     END IF
	END IF

C * MOVE TO NEXT X SECTION

	NSLICE = NSLICE + 1
	GOTO 10
	     END IF
	     PRINT *, LINE
20	CONTINUE

	END

	FUNCTION F( X,Y )
	REAL F, X, Y
	F = 50 * EXP( -.02 * (( X - 25 )**2 + ( Y - 25 )**2 ))

	END
