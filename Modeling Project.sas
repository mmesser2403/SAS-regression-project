libname IPEDS "/export/viya/homes/mm7401@uncw.edu/IPEDS";
options fmtsearch=(IPEDS);

/*PART 1*/

/**Explore the different IPEDS datasets**/
proc contents data=IPEDS.graduation;
run;

proc contents data=IPEDS.characteristics;
run;

proc contents data=IPEDS.tuitionandcosts;
run;

proc contents data=IPEDS.graduationextended;
run;

proc contents data=IPEDS.salaries;
run;

proc contents data=IPEDS.graduationextended;
run;


/** check the group variable */
proc freq data=IPEDS.graduation;
    tables group;
run;

proc freq data=IPEDS.graduationextended;
    tables group;
run;


/** checking professor groups **/
proc freq data=IPEDS.salaries;
    tables rank;
run;

/** checking format for all instruction staff **/
proc freq data=IPEDS.salaries;
    tables rank;
    format rank;
run;


/** create Graduation Rate table**/
proc sql;
    create table gradrate as
    select 
        a.unitid,
        a.Total as cohort_total,
        b.Total as completers_total,
        b.Total / a.Total as gradrate
    from IPEDS.graduation a
    join IPEDS.graduation b
        on a.unitid = b.unitid
        and b.group = "Completers within 150% of normal time"
    where a.group = "Incoming cohort (minus exclusions)"
        and a.Total >= 200;
quit;

/** summary statistics on GradRate **/
proc means data=gradrate n mean std min max;
    var cohort_total completers_total gradrate;
run;

/** merging variables form characteristics, tuition, costs and salaries tables **/

proc sql;
    create table project1 as
    select 
        g.*,
        c.instnm, c.control, c.hloffer,  
        c.locale, c.c21enprf, c.cbsatype, c.fips,
        t.tuition1, t.tuition2, t.fee2, t.fee3,
        t.roomcap,
        t.room, t.board,
        s.sa09mct as faculty_count,
        s.sa09mot as salary_total,
        s.sa09mot / s.sa09mct as avg_faculty_salary
    from gradrate g
    inner join IPEDS.characteristics c on g.unitid = c.unitid
    inner join IPEDS.tuitionandcosts t on g.unitid = t.unitid
    inner join IPEDS.salaries s on g.unitid = s.unitid
        and s.rank = 7;
quit;

/** Summary Statistics on project1 table **/
proc means data=project1 n nmiss mean std min max;
run;

/** check for CBSATYPE -2 format (not applicable) */
proc format library=IPEDS fmtlib;
    select CBSATYPE;
run;

/** check for missing values **/
proc means data=project1 nmiss;
run;


/** Explore categorical variables **/
proc freq data=project1;
    tables control hloffer locale c21enprf cbsatype room board;
run;

/** Checking format for Locale and hloffer **/
proc freq data=project1;
    tables locale hloffer;
    format locale hloffer;
run;

/** Simplifying locale and hloffer variables **/
data project1;
    set project1;
    
    /* Collapse locale into 4 categories */
    if locale in (11, 12, 13) then locale_collapse = 1;      /* City */
    else if locale in (21, 22, 23) then locale_collapse = 2; /* Suburb */
    else if locale in (31, 32, 33) then locale_collapse = 3; /* Town */
    else if locale in (41, 42, 43) then locale_collapse = 4; /* Rural */

    /* Collapse hloffer - merge postbacc cert (6) with bachelor's (5) */
    if hloffer in (5, 6) then hloffer_collapse = 1;          /* Bachelor's or Postbacc cert */
    else if hloffer = 7 then hloffer_collapse = 2;           /* Master's degree */
    else if hloffer = 8 then hloffer_collapse = 3;           /* Post-master's cert */
    else if hloffer = 9 then hloffer_collapse = 4;           /* Doctor's degree */

run;

/** verify encoding worked**/
proc freq data=project1;
    tables locale_collapse hloffer_collapse;
run;


proc freq data=project1;
    tables c21enprf board;
    format c21enprf board;
run;

/**simplifying c21enprf and board **/

data project1;
    set project1;
    
    /* Collapse c21enprf - merge 2-year (1) with 4-year (2) */
    if c21enprf in (1, 2) then c21enprf_collapse = 1;      /* Exclusively undergraduate */
    else if c21enprf = 3 then c21enprf_collapse = 2;        /* Very high undergraduate */
    else if c21enprf = 4 then c21enprf_collapse = 3;        /* High undergraduate */
    else if c21enprf = 5 then c21enprf_collapse = 4;        /* Majority undergraduate */
    else if c21enprf = 6 then c21enprf_collapse = 5;        /* Majority graduate */

    /* Collapse board to Yes/No */
    if board in (1, 2) then board_collapse = 1;             /* Yes */
    else if board = 3 then board_collapse = 0;              /* No */

run;


/* checking that recode worked*/
proc freq data=project1;
    tables c21enprf_collapse board_collapse;
run;


/* Correlation Check - Continuous Predictors*/
proc corr data=project1;
    var tuition2 fee2 fee3 roomcap avg_faculty_salary cohort_total;
run;



/*  Model Selection - Stepwise AICc */
proc glmselect data=project1;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=stepwise select=aicc;
run;


/* Model Selection - Forward AICc */
proc glmselect data=project1;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=forward select=aicc;
run;

/* Model Selection - Backward AICc */
proc glmselect data=project1;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=backward select=aicc;
run;


/* Model Selection - Forward SBC */
proc glmselect data=project1;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=forward select=sbc;
run;

/* Model Selection - Backward SBC */
proc glmselect data=project1;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=backward select=sbc;
run;

/* Model Selection - Stepwise SBC */
proc glmselect data=project1;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=stepwise select=sbc;
run;


/*  Model Selection - Forward Adj R² */
proc glmselect data=project1;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=forward select=adjrsq;
run;

/* Model Selection - Backward Adj R² */
proc glmselect data=project1;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=backward select=adjrsq;
run;

/* Model Selection - Stepwise Adj R² */
proc glmselect data=project1;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=stepwise select=adjrsq;
run;



/* Final Model - Full Diagnostics*/
proc glmselect data=project1 plots=all;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse room board_collapse;
    model gradrate = control hloffer_collapse locale_collapse 
                     c21enprf_collapse room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total
                     / selection=none;
run;



/*PART 2*/
/* Compute Median Graduation Rate */
proc means data=project1 median;
    var gradrate;
run;

/* cutoff of 0.599*/

/* Create Binary Outcome Variable */
data project2;
    set project1;
    above_median = (gradrate > 0.599);
run;

/* Verify the split */
proc freq data=project2;
    tables above_median;
run;


/* Explore Additional Candidate Variables */
proc freq data=project2;
    tables fips;
run;

proc corr data=project2;
    var tuition1 tuition2 fee2 fee3 roomcap cohort_total;
run;


/* Create Census Region Variable*/
data project2;
    set project2;
    
    /* Census Region based on FIPS state code */
    if fips in (9,23,25,33,44,50,34,36,42) then region = 1;        /* Northeast */
    else if fips in (17,18,26,39,55,19,20,27,29,31,38,46) then region = 2; /* Midwest */
    else if fips in (10,11,12,13,24,37,45,51,54,1,21,28,47,5,22,40,48) then region = 3; /* South */
    else if fips in (4,8,16,30,32,35,49,56,2,6,15,41,53) then region = 4; /* West */
    else region = 5; /* Territories */
run;

/* Verify */
proc freq data=project2;
    tables region;
run;

/*Drop Territories from Project 2*/
data project2;
    set project2;
    where region ne 5;
run;

/* Verify */
proc freq data=project2;
    tables region;
run;

/* Model Selection - Logistic Forward p=0.05*/
proc logistic data=project2;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse region / param=ref;
    model above_median(event='1') = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total region
                     / selection=forward slentry=0.05;
run;

/* Model Selection - Logistic Backward p=0.05 */
proc logistic data=project2;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse region / param=ref;
    model above_median(event='1') = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total region
                     / selection=backward slstay=0.05;
run;

/* Model Selection - Logistic Stepwise p=0.05 */
proc logistic data=project2;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse region / param=ref;
    model above_median(event='1') = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total region
                     / selection=stepwise slentry=0.05 slstay=0.05;
run;

/* Model Selection - Logistic Forward p=0.10 */
proc logistic data=project2;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse region / param=ref;
    model above_median(event='1') = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total region
                     / selection=forward slentry=0.10;
run;

/* Model Selection - Logistic Backward p=0.10 */
proc logistic data=project2;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse region / param=ref;
    model above_median(event='1') = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total region
                     / selection=backward slstay=0.10;
run;

/* Model Selection - Logistic Stepwise p=0.10 */
proc logistic data=project2;
    class control hloffer_collapse locale_collapse 
          c21enprf_collapse cbsatype room board_collapse region / param=ref;
    model above_median(event='1') = control hloffer_collapse locale_collapse 
                     c21enprf_collapse cbsatype room board_collapse
                     tuition2 fee2 avg_faculty_salary cohort_total region
                     / selection=stepwise slentry=0.10 slstay=0.10;
run;



/*   Rescale Variables for Interpretability */
data project2;
    set project2;
    tuition2_k    = tuition2 / 1000;        /* per $1,000 */
    fee2_100      = fee2 / 100;              /* per $100 */
    salary_k      = avg_faculty_salary / 1000; /* per $1,000 */
    cohort_100    = cohort_total / 100;      /* per 100 students */
run;

/* Final Model - Project 2 Logistic Regression */
proc logistic data=project2;
    model above_median(event='1') = tuition2_k fee2_100 salary_k cohort_100;
run;