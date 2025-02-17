      INTEGER FUNCTION test()
        IMPLICIT NONE
        INCLUDE "acc_testsuite.f90"
        INTEGER :: x, y !Iterators
        INTEGER,DIMENSION(LOOPCOUNT):: a !Data
        REAL(8),DIMENSION(LOOPCOUNT, 8):: randoms
        INTEGER,DIMENSION(LOOPCOUNT/10 + 1):: totals, totals_comparison
        INTEGER :: errors = 0

        !Initilization
        CALL RANDOM_SEED()
        CALL RANDOM_NUMBER(randoms)
        a = 0
        DO x = 1, LOOPCOUNT
          DO y = 1, 8
            IF (randoms(x, y) .gt. .933) THEN
              a(x) = a(x) + ISHFT(1, y - 1)
            END IF
          END DO
        END DO
        totals = 0
        totals_comparison = 0
        DO x = 1, LOOPCOUNT/10 + 1
          DO y = 0, 7
            totals(x) = totals(x) + ISHFT(1, y)
            totals_comparison(x) = totals_comparison(x) + ISHFT(1, y)
          END DO
        END DO

        !$acc data copyin(a(1:LOOPCOUNT)) copy(totals(1:(LOOPCOUNT/10 + 1)))
          !$acc parallel
            !$acc loop
            DO x = 1, LOOPCOUNT
              !$acc atomic
                totals(MOD(x, LOOPCOUNT/10 + 1) + 1) = iand(a(x), totals(MOD(x, LOOPCOUNT/10 + 1) + 1))
            END DO
          !$acc end parallel
        !$acc end data
        DO x = 1, LOOPCOUNT
          totals_comparison(MOD(x, LOOPCOUNT/10 + 1) + 1) = iand(totals_comparison(MOD(x, LOOPCOUNT/10 + 1) + 1), a(x))
        END DO
        DO x = 1, LOOPCOUNT/10 + 1
          IF (totals_comparison(x) .NE. totals(x)) THEN
            errors = errors + 1
            WRITE(*, *) totals_comparison(x)
          END IF
        END DO
        test = errors
      END


      PROGRAM test_kernels_async_main
      IMPLICIT NONE
      INTEGER :: failed, success !Number of failed/succeeded tests
      INTEGER :: num_tests,crosschecked, crossfailed, j
      INTEGER :: temp,temp1
      INCLUDE "acc_testsuite.f90"
      INTEGER test


      CHARACTER*50:: logfilename !Pointer to logfile
      INTEGER :: result

      num_tests = 0
      crosschecked = 0
      crossfailed = 0
      result = 1
      failed = 0

      !Open a new logfile or overwrite the existing one.
      logfilename = "test.log"
!      WRITE (*,*) "Enter logFilename:"
!      READ  (*,*) logfilename

      OPEN (1, FILE = logfilename)

      WRITE (*,*) "######## OpenACC Validation Suite V 1.0a ######"
      WRITE (*,*) "## Repetitions:", N
      WRITE (*,*) "## Loop Count :", LOOPCOUNT
      WRITE (*,*) "##############################################"
      WRITE (*,*)

      WRITE (*,*) "--------------------------------------------------"
      !WRITE (*,*) "Testing acc_kernels_async"
      WRITE (*,*) "Testing test_kernels_async"
      WRITE (*,*) "--------------------------------------------------"

      crossfailed=0
      result=1
      WRITE (1,*) "--------------------------------------------------"
      !WRITE (1,*) "Testing acc_kernels_async"
      WRITE (1,*) "Testing test_kernels_async"
      WRITE (1,*) "--------------------------------------------------"
      WRITE (1,*)
      WRITE (1,*) "testname: test_kernels_async"
      WRITE (1,*) "(Crosstests should fail)"
      WRITE (1,*)

      DO j = 1, N
        temp =  test()
        IF (temp .EQ. 0) THEN
          WRITE (1,*)  j, ". test successfull."
          success = success + 1
        ELSE
          WRITE (1,*) "Error: ",j, ". test failed."
          failed = failed + 1
        ENDIF
      END DO


      IF (failed .EQ. 0) THEN
        WRITE (1,*) "Directive worked without errors."
        WRITE (*,*) "Directive worked without errors."
        result = 0
        WRITE (*,*) "Result:",result
      ELSE
        WRITE (1,*) "Directive failed the test ", failed, " times."
        WRITE (*,*) "Directive failed the test ", failed, " times."
        result = failed * 100 / N
        WRITE (*,*) "Result:",result
      ENDIF
      CALL EXIT (result)
      END PROGRAM
