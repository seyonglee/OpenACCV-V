      INTEGER FUNCTION test()
        IMPLICIT NONE
        INCLUDE "acc_testsuite.fh"
        INTEGER :: x, y, z !Iterators
        INTEGER,DIMENSION(10*LOOPCOUNT):: a, b, b_copy !Data
        REAL(8),DIMENSION(10*LOOPCOUNT):: randoms2
        INTEGER,DIMENSION(10) :: c
        REAL(8) :: false_margin
        REAL(8),DIMENSION(160*LOOPCOUNT)::randoms
        INTEGER :: errors = 0
        INTEGER :: temp

        !Initilization
        CALL RANDOM_SEED()
        CALL RANDOM_NUMBER(randoms)
        CALL RANDOM_NUMBER(randoms2)
        b = FLOOR(10000 * randoms2)
        b_copy = b
        false_margin = exp(log(.5)/LOOPCOUNT)
        DO x = 1, 10 * LOOPCOUNT
          DO y = 1, 16
            IF (randoms((y - 1) * 10 * LOOPCOUNT + x) < false_margin) THEN
              temp = 1
              DO z = 1, y
                temp = temp * 2
              END DO
              a(x) = a(x) + temp
            END IF
          END DO
        END DO
        
        DO x = 1, 10
         c(x) = a((x - 1) * LOOPCOUNT + x)
        END DO
        
        

        !$acc data copyin(a(1:10*LOOPCOUNT)) copy(b(1:10*LOOPCOUNT), c(1:10))
          !$acc parallel loop gang private(temp)
          DO x = 1, 10
            temp = a((x - 1) * LOOPCOUNT + 1)
            !$acc loop worker reduction(iand:temp)
            DO y = 2, LOOPCOUNT
              temp = iand(temp, a((x - 1) * LOOPCOUNT + y))
            END DO
            c(x) = temp
            !$acc loop worker
            DO y = 1, LOOPCOUNT
              b((x - 1) * LOOPCOUNT + y) = b((x - 1) * LOOPCOUNT + y) + c(x)
            END DO
          END DO
        !$acc end data

       DO x = 1, 10
         temp = a((x - 1) * LOOPCOUNT + 1)
         DO y = 2, LOOPCOUNT
           temp = iand(temp, a((x - 1) * LOOPCOUNT + y))
         END DO
         IF (temp .ne. c(x)) THEN
           errors = errors + 1
         END IF
         DO y = 1, LOOPCOUNT
           IF (b((x - 1) * LOOPCOUNT + y) .ne. b_copy((x - 1) * LOOPCOUNT + y) + temp) THEN
             errors = errors + 1
           END IF
         END DO
       END DO
       
       test = errors 
      END


      PROGRAM test_kernels_async_main
      IMPLICIT NONE
      INTEGER :: failed, success !Number of failed/succeeded tests
      INTEGER :: num_tests,crosschecked, crossfailed, j
      INTEGER :: temp,temp1
      INCLUDE "acc_testsuite.fh"
      INTEGER test


      CHARACTER*50:: logfilename !Pointer to logfile
      INTEGER :: result

      num_tests = 0
      crosschecked = 0
      crossfailed = 0
      result = 1
      failed = 0

      !Open a new logfile or overwrite the existing one.
      logfilename = "OpenACC_testsuite.log"
!      WRITE (*,*) "Enter logFilename:"
!      READ  (*,*) logfilename

      OPEN (1, FILE = logfilename)

      WRITE (*,*) "######## OpenACC Validation Suite V 2.5 ######"
      WRITE (*,*) "## Repetitions:", N
      WRITE (*,*) "## Loop Count :", LOOPCOUNT
      WRITE (*,*) "##############################################"
      WRITE (*,*)

      WRITE (*,*) "--------------------------------------------------"
      WRITE (*,*) "Test of parallel_loop_reduction_bitand_loop"
      WRITE (*,*) "--------------------------------------------------"

      crossfailed=0
      result=1
      WRITE (1,*) "--------------------------------------------------"
      WRITE (1,*) "Test of parallel_loop_reduction_bitand_loop"
      WRITE (1,*) "--------------------------------------------------"
      WRITE (1,*)
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
                                             

