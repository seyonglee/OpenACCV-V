#include "acc_testsuite.h"

bool is_possible(real_t* a, real_t* b, int length, real_t prev){
    if (length == 0){
        return true;
    }
    real_t *passed_a = (real_t *)malloc((length - 1) * sizeof(real_t));
    real_t *passed_b = (real_t *)malloc((length - 1) * sizeof(real_t));
    for (int x = 0; x < length; ++x){
        if (fabs(b[x] - (a[x]/prev)) < PRECISION){
            for (int y = 0; y < x; ++y){
                passed_a[y] = a[y];
                passed_b[y] = b[y];
            }
            for (int y = x + 1; y < length; ++y){
                passed_a[y - 1] = a[y];
                passed_b[y - 1] = b[y];
            }
            if (is_possible(passed_a, passed_b, length - 1, b[x])){
                free(passed_a);
                free(passed_b);
                return true;
            }
        }
    }
    free(passed_a);
    free(passed_b);
    return false;
}

bool possible_result(real_t * remaining_combinations, int length, real_t current_value, real_t test_value){
    if (length == 0){
        if (fabs(current_value - test_value) > PRECISION){
            return true;
        }
        else {
            return false;
        }
    }
    real_t * passed = (real_t *)malloc((length - 1) * sizeof(real_t));
    for (int x = 0; x < length; ++x){
        for (int y = 0; y < x; ++y){
            passed[y] = remaining_combinations[y];
        }
        for (int y = x + 1; y < length; ++y){
            passed[y - 1] = remaining_combinations[y];
        }
        if (possible_result(passed, length - 1, remaining_combinations[x] / current_value, test_value)){
            free(passed);
            return true;
        }
    }
    free(passed);
    return false;
}

int test(){
    int err = 0;
    srand(time(NULL));
    real_t *a = (real_t *)malloc(n * sizeof(real_t));
    real_t *b = (real_t *)malloc(n * sizeof(real_t));
    real_t *c = (real_t *)malloc(n * sizeof(real_t));
    real_t *totals = (real_t *)malloc((n/10 + 1) * sizeof(real_t));

    for (int x = 0; x < n; ++x){
        a[x] = rand() / (real_t)(RAND_MAX / 10);
        b[x] = rand() / (real_t)(RAND_MAX / 10);
    }
    for (int x = 0; x < n/10 + 1; ++x){
        totals[x] = 1;
    }

    #pragma acc data copyin(a[0:n], b[0:n]) copy(totals[0:n/10 + 1]) copyout(c[0:n])
    {
        #pragma acc parallel
        {
            #pragma acc loop
            for (int x = 0; x < n; ++x){
                #pragma acc atomic capture
                    c[x] = totals[x%(n/10 + 1)] = (a[x] + b[x]) / totals[x%(n/10 + 1)];
            }
        }
    }

    real_t * passed = (real_t *)malloc(10 * sizeof(real_t));
    int indexer;

    for (int x = 0; x < (n/10 + 1); ++x){
        indexer = x;
        while (indexer < n){
            passed[indexer/(n/10 + 1)] = (a[x] + b[x]);
            indexer += (n/10 + 1);
        }
        if (!(possible_result(passed, 10, 1, totals[x]))){
            err += 1;
        }
    }

    real_t *passed_ab = (real_t *)malloc(10 * sizeof(real_t));
    real_t *passed_c = (real_t *)malloc(10 * sizeof(real_t));
    int passed_indexer;
    int absolute_indexer;
    for (int x = 0; x < (n/10 + 1); ++x){
        for (passed_indexer = 0, absolute_indexer = x; absolute_indexer < n; passed_indexer++, absolute_indexer += n/10 + 1){
            passed_ab[passed_indexer] = a[absolute_indexer] + b[absolute_indexer];
            passed_c[passed_indexer] = c[absolute_indexer];
        }
        if (!is_possible(passed_ab, passed_c, passed_indexer - 1, 1)){
            err++;
        }
    }


    free(a);
    free(b);
    free(c);
    free(passed);
    free(passed_ab);
    free(passed_c);
    free(totals);
    return err;
}


int main()
{
  int i;			/* Loop index */
  int result;		/* return value of the program */
  int failed=0; 		/* Number of failed tests */
  int success=0;		/* number of succeeded tests */
  static FILE * logFile;	/* pointer onto the logfile */
  static const char * logFileName = "test_acc_lib_acc_wait.log";	/* name of the logfile */


  /* Open a new Logfile or overwrite the existing one. */
  logFile = fopen(logFileName,"w+");

  printf("######## OpenACC Validation Suite V %s #####\n", ACCTS_VERSION );
  printf("## Repetitions: %3d                       ####\n",REPETITIONS);
  printf("## Array Size : %.2f MB                 ####\n",ARRAYSIZE * ARRAYSIZE/1e6);
  printf("##############################################\n");
  printf("Testing test_acc_lib_acc_wait\n\n");

  fprintf(logFile,"######## OpenACC Validation Suite V %s #####\n", ACCTS_VERSION );
  fprintf(logFile,"## Repetitions: %3d                       ####\n",REPETITIONS);
  fprintf(logFile,"## Array Size : %.2f MB                 ####\n",ARRAYSIZE * ARRAYSIZE/1e6);
  fprintf(logFile,"##############################################\n");
  fprintf(logFile,"Testing test_acc_lib_acc_wait\n\n");

  for ( i = 0; i < REPETITIONS; i++ ) {
    fprintf (logFile, "\n\n%d. run of test_acc_lib_acc_wait out of %d\n\n",i+1,REPETITIONS);
    if (test() == 0) {
      fprintf(logFile,"Test successful.\n");
      success++;
    } else {
      fprintf(logFile,"Error: Test failed.\n");
      printf("Error: Test failed.\n");
      failed++;
    }
  }

  if(failed==0) {
    fprintf(logFile,"\nDirective worked without errors.\n");
    printf("Directive worked without errors.\n");
    result=0;
  } else {
    fprintf(logFile,"\nDirective failed the test %i times out of %i. %i were successful\n",failed,REPETITIONS,success);
    printf("Directive failed the test %i times out of %i.\n%i test(s) were successful\n",failed,REPETITIONS,success);
    result = (int) (((double) failed / (double) REPETITIONS ) * 100 );
  }
  printf ("Result: %i\n", result);
  return result;
}
