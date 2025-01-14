      INTEGER FUNCTION test()
        USE OPENACC
        IMPLICIT NONE
        INCLUDE "acc_testsuite.f90"
        INTEGER :: x !Iterators
        REAL(8),DIMENSION(LOOPCOUNT):: a, b, c, a_copy, b_copy !Data
        INTEGER :: errors = 0
        LOGICAL,DIMENSION(1):: devtest
        CALL RANDOM_SEED()
        devtest(1) = .TRUE.
        !$acc enter data copyin(devtest(1:1))
        !$acc parallel present(devtest(1:1))
          devtest(1) = .FALSE.
        !$acc end parallel
        !Initilization

        CALL RANDOM_NUMBER(a)
        CALL RANDOM_NUMBER(b)
        c = 0

        CALL acc_copyin(a(1:LOOPCOUNT))
        CALL acc_copyin(b(1:LOOPCOUNT))

        !$acc data copy(c(1:LOOPCOUNT))
          !$acc parallel present(a(1:LOOPCOUNT), b(1:LOOPCOUNT))
            !$acc loop
            DO x = 1, LOOPCOUNT
              c(x) = a(x) + b(x)
            END DO
          !$acc end parallel
        !$acc end data

        !$acc exit data copyout(a(1:LOOPCOUNT), b(1:LOOPCOUNT))

        DO x = 1, LOOPCOUNT
          IF (abs(c(x) - (a(x) + b(x))) .gt. PRECISION) THEN
            errors = errors + 1
          END IF
        END DO

        CALL RANDOM_NUMBER(a)
        CALL RANDOM_NUMBER(b)
        c = 1

        CALL acc_copyin(a(1:LOOPCOUNT))
        CALL acc_copyin(b(1:LOOPCOUNT))

        !$acc data copyout(c(1:LOOPCOUNT))
          !$acc parallel present(a(1:LOOPCOUNT), b(1:LOOPCOUNT))
            !$acc loop
            DO x = 1, LOOPCOUNT
              c(x) = a(x) + b(x)
            END DO
          !$acc end parallel
        !$acc end data

        CALL acc_copyout(a(1:LOOPCOUNT))
        CALL acc_copyout(b(1:LOOPCOUNT))

        DO x = 1, LOOPCOUNT
          IF (abs(c(x) - (a(x) + b(x))) .gt. PRECISION) THEN
            errors = errors + 1
          END IF
        END DO

        IF (devtest(1) .eqv. .TRUE.) THEN
          CALL RANDOM_NUMBER(a)
          a_copy(:) = a(:)
          CALL RANDOM_NUMBER(b)
          b_copy(:) = b(:)
          c = 0

          CALL acc_copyin(a(1:LOOPCOUNT))
          CALL acc_copyin(b(1:LOOPCOUNT))

          a = 0
          b = 0

          !$acc data copyin(a(1:LOOPCOUNT), b(1:LOOPCOUNT)) copyout(c(1:LOOPCOUNT))
            !$acc parallel
              !$acc loop
              DO x = 1, LOOPCOUNT
                c(x) = a(x) + b(x)
              END DO
            !$acc end parallel
          !$acc end data

          !$acc exit data copyout(a(1:LOOPCOUNT), b(1:LOOPCOUNT))

          DO x = 1, LOOPCOUNT
            IF (abs(a(x) - a_copy(x)) .gt. PRECISION) THEN
              errors = errors + 1
            END IF
            IF (abs(b(x) - b_copy(x)) .gt. PRECISION) THEN
              errors = errors + 1
            END IF
            IF (abs(c(x) - (a(x) + b(x))) .gt. PRECISION) THEN
              errors = errors + 1
            END IF
          END DO
        END IF

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
