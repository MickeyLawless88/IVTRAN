

	PROGRAM HEMI
	CHARACTER*101 LINE
	
	DO 66 X = -30.0, 30.0, .03333
	   DO 55 IY = 1, 101
	      Y = REAL( IY - 51 ) / 50.0
	      R = X**2 + Y**2
	      Z = SQRT( 1.0 - MIN( R, 1.0 ))
	      LINE( IY:IY ) = MOD( NINT( 10.0 * Z ), 10 )
55         CONTINUE
	   PRINT 77, X, LINE
77         FORMAT(1X,F10.5,8X,A101)
66      CONTINUE

	END
