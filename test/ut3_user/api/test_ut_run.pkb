create or replace package body test_ut_run is

  gc_owner               constant varchar2(250) := sys_context('userenv', 'current_schema');
  gc_module              constant varchar2(32767) := 'test module';
  gc_action              constant varchar2(32767) := 'test action';
  gc_client_info         constant varchar2(32767) := 'test client info';

  g_context_test_results clob;

  procedure clear_expectations is
  begin
    ut3_tester_helper.main_helper.clear_expectations();
  end;

  procedure create_ut3$user#_tests is
  begin
    ut3_tester_helper.run_helper.create_ut3$user#_tests();
  end;
  
  procedure drop_ut3$user#_tests is
  begin
    ut3_tester_helper.run_helper.drop_ut3$user#_tests();
  end;

  procedure ut_version is
  begin
    ut.expect(ut3.ut.version()).to_match('^v\d+\.\d+\.\d+\.\d+(-\w+)?$');
  end;

  procedure ut_fail is
  begin
    --Act
    ut3.ut.fail('Testing failure message');
    --Assert
    ut.expect(ut3_tester_helper.main_helper.get_failed_expectations(1))
      .to_be_like('%Testing failure message%');
  end;

  procedure run_proc_no_params is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run();
    l_results := ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_proc_specific_reporter is
    l_results clob;
  begin
    --Act
    ut3.ut.run('ut3_tester_helper',a_reporter => ut3.ut_documentation_reporter() );
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_proc_cov_file_list is
    l_results clob;
  begin
    --Act
    ut3.ut.run(
      'ut3_tester_helper',
      a_reporter => ut3.ut_sonar_test_reporter(), 
      a_source_files => ut3.ut_varchar2_list(),
      a_test_files => ut3.ut_varchar2_list('tests/ut3_tester_helper.test_package_1.pkb',
        'tests/ut3_tester_helper.test_package_2.pkb',
        'tests/ut3_tester_helper.test_package_3.pkb')
      );
      
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%tests/ut3_tester_helper.test_package_2.pkb'||
      '%tests/ut3_tester_helper.test_package_1.pkb'||
      '%tests/ut3_tester_helper.test_package_3.pkb%' );
  end;

  procedure run_proc_pkg_name is
    l_results clob;
  begin
    ut3.ut.run('ut3_tester_helper.test_package_1');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );
  end;

  procedure run_proc_pkg_name_file_list is
    l_results clob;
  begin
     ut3.ut.run(
       'ut3_tester_helper.test_package_3',
       ut3.ut_sonar_test_reporter(), a_source_files => ut3.ut_varchar2_list(),
       a_test_files => ut3.ut_varchar2_list('tests/ut3_tester_helper.test_package_1.pkb',
         'tests/ut3_tester_helper.test_package_2.pkb',
         'tests/ut3_tester_helper.test_package_3.pkb')
       );
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%tests/ut3_tester_helper.test_package_3.pkb%' );
    ut.expect( l_results ).not_to_be_like( '%tests/ut3_tester_helper.test_package_1.pkb%' );
    ut.expect( l_results ).not_to_be_like( '%tests/ut3_tester_helper.test_package_2.pkb%' );
  end;

  procedure run_proc_path_list is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(ut3.ut_varchar2_list(':tests.test_package_1',':tests'));
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );
  end;

  procedure run_proc_path_list_file_list is
    l_results clob;
  begin
     ut3_tester_helper.run_helper.run(
       a_paths => ut3.ut_varchar2_list(':tests.test_package_1',':tests'),
       a_reporter => ut3.ut_sonar_test_reporter(), 
       a_test_files => ut3.ut_varchar2_list('tests/ut3_tester_helper.test_package_1.pkb',
         'tests/ut3_tester_helper.test_package_2.pkb',
         'tests/ut3_tester_helper.test_package_3.pkb')
       );
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%tests/ut3_tester_helper.test_package_1.pkb%' );
    ut.expect( l_results ).to_be_like( '%tests/ut3_tester_helper.test_package_2.pkb%' );
    ut.expect( l_results ).not_to_be_like( '%tests/ut3_tester_helper.test_package_3.pkb%' );
  end;

  procedure run_proc_null_reporter is
    l_results clob;
  begin
    --Act
    ut3.ut.run('ut3_tester_helper', cast(null as ut3.ut_reporter_base));
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%tests%test_package_1%test_package_2%tests2%test_package_3%' );
  end;

  procedure run_proc_null_path is
    l_results clob;
  begin
    --Act
    ut3_tester_helper.run_helper.run(cast(null as varchar2));
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_proc_null_path_list is
    l_results clob;
    l_paths   ut3.ut_varchar2_list;
  begin
    --Act
    ut3_tester_helper.run_helper.run(l_paths);
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_proc_empty_path_list is
    l_results clob;
  begin
    --Act
    ut3_tester_helper.run_helper.run(ut3.ut_varchar2_list());
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure create_suite_with_commit is
    pragma autonomous_transaction;
  begin
    execute immediate 'create or replace package test_commit_warning is
      --%suite
      --%suitepath(ut.run.transaction)

      --%test
      procedure does_commit;
    end;';
    execute immediate 'create or replace package body test_commit_warning is
      procedure does_commit is
      begin
        ut3.ut.expect(1).to_equal(1);
        commit;
      end;
    end;';
  end;

  procedure drop_suite_with_commit is
    pragma autonomous_transaction;
    begin
      execute immediate 'drop package test_commit_warning';
    end;

  procedure run_proc_warn_on_commit is
    l_results clob;
  begin
    ut3.ut.run('test_commit_warning');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    ut.expect(l_results).to_be_like(
      '%Unable to perform automatic rollback after test%'||
      'An implicit or explicit commit/rollback occurred in procedures:%' ||
      'does_commit%' ||
      'Use the "--%rollback(manual)" annotation or remove commit/rollback/ddl statements that are causing the issue.%'
    );
  end;

  procedure create_failing_beforeall_suite is
    pragma autonomous_transaction;
  begin
    execute immediate 'create or replace package parent_suite is
      --%suite
      --%suitepath(ut.run.failing_setup)

      --%beforeall
      procedure failing_setup;
    end;';
    execute immediate 'create or replace package body parent_suite is
      procedure failing_setup is
      begin
        raise no_data_found;
      end;
    end;';
    execute immediate 'create or replace package child_suite is
      --%suite
      --%suitepath(ut.run.failing_setup.parent_suite.some_sub_suite)

      --%test
      procedure does_stuff;
    end;';
    execute immediate 'create or replace package body child_suite is
      procedure does_stuff is
      begin
        ut3.ut.expect(1).to_equal(1);
      end;
    end;';
  end;

  procedure drop_failing_beforeall_suite is
    pragma autonomous_transaction;
    begin
      execute immediate 'drop package parent_suite';
      execute immediate 'drop package child_suite';
    end;

  procedure run_proc_fail_child_suites is
    l_results clob;
  begin
    ut3.ut.run('child_suite');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    ut.expect(l_results).to_be_like(
      '%1) does_stuff%' ||
        'ORA-01403: no data found%' ||
        'ORA-06512: at "UT3$USER#.PARENT_SUITE%'
    );
  end;

  procedure transaction_setup is
    pragma autonomous_transaction;
  begin
    execute immediate 'create table transaction_test_table(message varchar2(100))';
    execute immediate 'create or replace package test_transaction is
      --%suite

      --%test
      procedure insert_row;

      --%test
      procedure insert_and_raise;
    end;
    ';
    execute immediate 'create or replace package body test_transaction is
        procedure insert_row is
        begin
          insert into transaction_test_table values (''2 - inside the test_transaction.insert_row test'');
        end;
        procedure insert_and_raise is
        begin
          insert into transaction_test_table values (''2 - inside the test_transaction.insert_row test'');
          raise no_data_found;
        end;
      end;
    ';

  end;

  procedure transaction_cleanup is
    pragma autonomous_transaction;
  begin
    begin
      execute immediate 'drop table transaction_test_table';
    exception
      when others then null;
    end;
    begin
      execute immediate 'drop package test_transaction';
    exception
      when others then null;
    end;
  end;

  procedure run_proc_keep_test_data is
    l_expected sys_refcursor;
    l_actual   sys_refcursor;
    l_results  clob;
  begin
    --Arrange
    execute immediate '
      insert into transaction_test_table values (''1 - inside the test_ut_run.run_proc_keep_test_changes test'')';

    --Act
    ut3.ut.run('test_transaction.insert_row', a_force_manual_rollback => true);
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();

    --Assert
    open l_expected for
    select '1 - inside the test_ut_run.run_proc_keep_test_changes test' as message from dual
    union all
    select '2 - inside the test_transaction.insert_row test' from dual
    order by 1;

    open l_actual for 'select * from transaction_test_table order by 1';

    ut.expect( l_actual ).to_equal(l_expected);
  end;

  procedure run_proc_keep_test_data_raise is
    l_expected sys_refcursor;
    l_actual   sys_refcursor;
    l_results  clob;
  begin
    --Arrange
    execute immediate '
      insert into transaction_test_table values (''1 - inside the test_ut_run.run_proc_keep_test_changes test'')';

    --Act
    ut3.ut.run('test_transaction.insert_and_raise', a_force_manual_rollback => true);
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();

    --Assert
    open l_expected for
    select '1 - inside the test_ut_run.run_proc_keep_test_changes test' as message from dual
    union all
    select '2 - inside the test_transaction.insert_row test' from dual
    order by 1;

    open l_actual for 'select * from transaction_test_table order by 1';

    ut.expect( l_actual ).to_equal(l_expected);
  end;

  procedure run_proc_discard_test_data is
    l_expected sys_refcursor;
    l_actual   sys_refcursor;
    l_results  clob;
  begin
    --Arrange
    execute immediate '
      insert into transaction_test_table values (''1 - inside the test_ut_run.run_proc_keep_test_changes test'')';

    --Act
    ut3.ut.run('test_transaction.insert_row');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();

    --Assert
    open l_expected for
    select '1 - inside the test_ut_run.run_proc_keep_test_changes test' as message from dual;

    open l_actual for 'select * from transaction_test_table order by 1';

    ut.expect( l_actual ).to_equal(l_expected);
  end;

  procedure run_func_no_params is
    l_results   ut3.ut_varchar2_list;
  begin
    l_results := ut3_tester_helper.run_helper.run();
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_specific_reporter is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
    l_results := ut3_tester_helper.run_helper.run(ut3.ut_documentation_reporter());
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_cov_file_list is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
  select * bulk collect into l_results from table (
    ut3.ut.run('ut3_tester_helper',
      ut3.ut_sonar_test_reporter(), 
      a_source_files => ut3.ut_varchar2_list(),
      a_test_files => ut3.ut_varchar2_list('tests/ut3_tester_helper.test_package_1.pkb',
        'tests/ut3_tester_helper.test_package_2.pkb',
        'tests/ut3_tester_helper.test_package_3.pkb')
      ));
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%tests/ut3_tester_helper.test_package_2.pkb%tests/ut3_tester_helper.test_package_1.pkb%tests/ut3_tester_helper.test_package_3.pkb%' );
  end;

  procedure run_func_pkg_name is
    l_results   ut3.ut_varchar2_list;
  begin
    select * bulk collect into l_results from table (ut3.ut.run('ut3_tester_helper.test_package_1'));
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%test_package_2%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%test_package_3%' );
  end;

  procedure run_func_pkg_name_file_list is
    l_results   ut3.ut_varchar2_list;
  begin
  select * bulk collect into l_results from table (
    ut3.ut.run('ut3_tester_helper.test_package_3',
      ut3.ut_sonar_test_reporter(), 
      a_source_files => ut3.ut_varchar2_list(),
      a_test_files => ut3.ut_varchar2_list('tests/ut3_tester_helper.test_package_1.pkb',
        'tests/ut3_tester_helper.test_package_2.pkb',
        'tests/ut3_tester_helper.test_package_3.pkb')
      ));
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%tests/ut3_tester_helper.test_package_3.pkb%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%tests/ut3_tester_helper.test_package_1.pkb%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%tests/ut3_tester_helper.test_package_2.pkb%' );
  end;

  procedure run_func_path_list is
    l_results   ut3.ut_varchar2_list;
  begin
    l_results := ut3_tester_helper.run_helper.run(ut3.ut_varchar2_list(':tests.test_package_1',':tests'));
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_2%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%test_package_3%' );
  end;

  procedure run_func_path_list_file_list is
    l_results   ut3.ut_varchar2_list;
  begin
    l_results := ut3_tester_helper.run_helper.run(
      a_paths => ut3.ut_varchar2_list(':tests.test_package_1',':tests'),
      a_reporter => ut3.ut_sonar_test_reporter(), 
      a_test_files => ut3.ut_varchar2_list('tests/ut3_tester_helper.test_package_1.pkb',
        'tests/ut3_tester_helper.test_package_2.pkb',
        'tests/ut3_tester_helper.test_package_3.pkb')
      );
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%tests/ut3_tester_helper.test_package_1.pkb%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%tests/ut3_tester_helper.test_package_2.pkb%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%tests/ut3_tester_helper.test_package_3.pkb%' );
  end;

  procedure run_func_null_reporter is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
    select * bulk collect into l_results from table (ut3.ut.run('ut3_tester_helper',cast(null as ut3.ut_reporter_base)));
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%tests%test_package_1%test_package_2%tests2%test_package_3%' );
  end;

  procedure run_func_null_path is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
    l_results := ut3_tester_helper.run_helper.run(cast(null as varchar2));
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_null_path_list is
    l_results   ut3.ut_varchar2_list;
    l_paths   ut3.ut_varchar2_list;
  begin
    --Act
    l_results := ut3_tester_helper.run_helper.run(l_paths);
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_empty_path_list is
    l_results   ut3.ut_varchar2_list;
  begin
    --Act
    l_results := ut3_tester_helper.run_helper.run(ut3.ut_varchar2_list());
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_cov_file_lst_null_rep is
    l_results  ut3.ut_varchar2_list;
  begin
    --Act
    l_results := ut3_tester_helper.run_helper.run(
      a_test_files => ut3.ut_varchar2_list('tests/ut3_tester_helper.test_package_1.pkb',
      'tests/ut3_tester_helper.test_package_2.pkb',
      'tests/ut3_tester_helper.test_package_3.pkb'),
      a_reporter => cast(null as ut3.ut_reporter_base));
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure run_func_empty_suite is
    l_results   ut3.ut_varchar2_list;
    l_expected  varchar2(32767);
    pragma autonomous_transaction;
  begin
    --Arrange
    execute immediate q'[create or replace package empty_suite as
      -- %suite

      procedure not_a_test;
    end;]';
    execute immediate q'[create or replace package body empty_suite as
      procedure not_a_test is begin null; end;
    end;]';
    l_expected := '%empty_suite%0 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)%';
    --Act
    select * bulk collect into l_results from table(ut3.ut.run('empty_suite'));

    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( l_expected );

    --Cleanup
    execute immediate q'[drop package empty_suite]';
  end;

  procedure raise_in_invalid_state is
    l_results   ut3.ut_varchar2_list;
    l_expected  varchar2(32767);
  begin
    --Arrange
    l_expected := 'test_state
  test_stateful
    failing_stateful_test [% sec] (FAILED - 1)%
Failures:%
  1) failing_stateful_test
      ORA-04068: existing state of packages (DB_LOOPBACK%) has been discarded
      ORA-04061: existing state of package body "%.STATEFUL_PACKAGE" has been invalidated
      ORA-04065: not executed, altered or dropped package body "%.STATEFUL_PACKAGE"%
      ORA-06512: at line 6%
1 tests, 0 failed, 1 errored, 0 disabled, 0 warning(s)%';

    --Act
    select * bulk collect into l_results from table(ut3.ut.run('ut3_tester_helper.test_stateful'));
  
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( l_expected );
    ut.fail('Expected exception but nothing was raised');
  exception
    when others then
      ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( l_expected );
      ut.expect(sqlcode).to_equal(-4068);
  end;
  
  procedure create_test_suite is
  begin
    ut3_tester_helper.run_helper.create_test_suite;
  end;
  
  procedure drop_test_suite is
  begin
    ut3_tester_helper.run_helper.drop_test_suite;
  end;

  procedure run_in_invalid_state is
    l_results   ut3.ut_varchar2_list;
    l_actual    clob;
    l_expected  varchar2(32767);
  begin
    select * bulk collect into l_results from table(ut3.ut.run('failing_invalid_spec'));
    
    l_actual :=  ut3_tester_helper.main_helper.table_to_clob(l_results);
    ut.expect(l_actual).to_be_like('%Call params for % are not valid: package %FAILING_INVALID_SPEC% does not exist or is invalid.%');
    
  end;

  procedure compile_invalid_package is
    ex_compilation_error exception;
    pragma exception_init(ex_compilation_error,-24344);
    pragma autonomous_transaction;
  begin
    begin
      execute immediate q'[
        create or replace package failing_invalid_spec as
        --%suite
        gv_glob_val non_existing_table.id%type := 0;

        --%test
        procedure test1;
      end;]';
    exception when ex_compilation_error then null;
    end;
    begin
      execute immediate q'[
        create or replace package body failing_invalid_spec as
          procedure test1 is begin ut.expect(1).to_equal(1); end;
        end;]';
    exception when ex_compilation_error then null;
    end;
  end;
  procedure drop_invalid_package is
    pragma autonomous_transaction;
  begin
    execute immediate 'drop package failing_invalid_spec';
  end;

  procedure run_and_revalidate_specs is
    l_results   ut3.ut_varchar2_list;
    l_actual    clob;
    l_is_invalid number;
  begin
    execute immediate q'[select count(1) from all_objects o where o.owner = :object_owner and o.object_type = 'PACKAGE'
            and o.status = 'INVALID' and o.object_name= :object_name]' into l_is_invalid
            using 'UT3$USER#','INVALID_PCKAG_THAT_REVALIDATES';

    select * bulk collect into l_results from table(ut3.ut.run('invalid_pckag_that_revalidates'));
    
    l_actual :=  ut3_tester_helper.main_helper.table_to_clob(l_results);
    ut.expect(1).to_equal(l_is_invalid);
    ut.expect(l_actual).to_be_like('%invalid_pckag_that_revalidates%invalidspecs [% sec]%
%Finished in % seconds%
%1 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)%'); 
  
  end;

  procedure generate_invalid_spec is
    ex_compilation_error exception;
    pragma exception_init(ex_compilation_error,-24344);
    pragma autonomous_transaction;
  begin
  
    execute immediate q'[
      create or replace package parent_specs as
        c_test constant varchar2(1) := 'Y';
      end;]';
  
    execute immediate q'[
      create or replace package invalid_pckag_that_revalidates as
        --%suite
        g_var varchar2(1) := parent_specs.c_test;

        --%test(invalidspecs)
        procedure test1;
      end;]';

    execute immediate q'[
      create or replace package body invalid_pckag_that_revalidates as
        procedure test1 is begin ut.expect('Y').to_equal(g_var); end;
      end;]';
    
    -- That should invalidate test package and we can then revers
    execute immediate q'[
      create or replace package parent_specs as
        c_test_error constant varchar2(1) := 'Y';
      end;]';
 
    execute immediate q'[
      create or replace package parent_specs as
        c_test constant varchar2(1) := 'Y';
      end;]';

  end;
  procedure drop_invalid_spec is
    pragma autonomous_transaction;
  begin
    execute immediate 'drop package invalid_pckag_that_revalidates';
    execute immediate 'drop package parent_specs';
  end;

  procedure run_and_report_warnings is
    l_results   ut3.ut_varchar2_list;
    l_actual    clob;
  begin

    select * bulk collect into l_results from table(ut3.ut.run('bad_annotations'));
    l_actual :=  ut3_tester_helper.main_helper.table_to_clob(l_results);

    ut.expect(l_actual).to_be_like('%Invalid annotation "--%context". Cannot find following "--%endcontext". Annotation ignored.%
%1 tests, 0 failed, 0 errored, 0 disabled, 1 warning(s)%');

  end;

  procedure create_bad_annot is
    pragma autonomous_transaction;
  begin
    execute immediate q'[
    create or replace package bad_annotations as
      --%suite

      --%context

      --%test(invalidspecs)
      procedure test1;

    end;]';

    execute immediate q'[
    create or replace package body bad_annotations as
      procedure test1 is begin ut.expect(1).to_equal(1); end;
    end;]';

  end;

  procedure drop_bad_annot is
    pragma autonomous_transaction;
  begin
    execute immediate 'drop package bad_annotations';
  end;

  procedure create_suite_with_link is
  begin
    ut3_tester_helper.run_helper.create_suite_with_link;
  end;

  procedure drop_suite_with_link is
  begin
    ut3_tester_helper.run_helper.drop_suite_with_link;
  end;

  procedure savepoints_on_db_links is
    l_results clob;
  begin
    ut3.ut.run('ut3_tester_helper.test_distributed_savepoint');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    ut.expect(l_results).to_be_like('%1 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)%');
  end;

    procedure remove_time_from_results(a_results in out nocopy ut3.ut_varchar2_list) is
  begin
    for i in 1 .. a_results.count loop
      a_results(i) := regexp_replace(a_results(i),'\[[0-9]*[\.,][0-9]+ sec\]','');
      a_results(i) := regexp_replace(a_results(i),'Finished in [0-9]*[\.,][0-9]+ seconds','');
    end loop;
  end;

  procedure run_schema_name_test is
    l_results    ut3.ut_varchar2_list;
    l_expected   clob;
  begin
    select * bulk collect into l_results
      from table ( ut3.ut.run( gc_owner||'.'||gc_owner ) );
    l_expected := '%1 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)%';
    ut.expect(ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( l_expected );
  end;

  procedure create_schema_name_package is
    pragma autonomous_transaction;
  begin
    execute immediate '
    create or replace package '||gc_owner||'.'||gc_owner||' as
      --%suite

      --%test
      procedure sample_test;
    end;';

    execute immediate '
    create or replace package body '||gc_owner||'.'||gc_owner||' as
      procedure sample_test is begin ut.expect(1).to_equal(1); end;
    end;';

  end;

  procedure drop_schema_name_package is
    pragma autonomous_transaction;
  begin
    execute immediate 'drop package '||gc_owner||'.'||gc_owner;
  end;

  procedure run_with_random_order is
    l_random_results ut3.ut_varchar2_list;
    l_results        ut3.ut_varchar2_list;
  begin
    select * bulk collect into l_random_results
      from table ( ut3.ut.run( 'ut3_tester_helper.test_package_1', a_random_test_order_seed => 3 ) )
     where trim(column_value) is not null and column_value not like 'Finished in %'
      and column_value not like '%Tests were executed with random order %';

    select * bulk collect into l_results
    from table ( ut3.ut.run( 'ut3_tester_helper.test_package_1' ) )
    --TODO this condition should be removed once issues with unordered compare and 'blank text rows' are resolved.
    where trim(column_value) is not null and column_value not like 'Finished in %';

    remove_time_from_results(l_results);
    remove_time_from_results(l_random_results);

    ut.expect(anydata.convertCollection(l_random_results)).to_equal(anydata.convertCollection(l_results)).unordered();
    ut.expect(anydata.convertCollection(l_random_results)).not_to_equal(anydata.convertCollection(l_results));
  end;

  procedure run_and_report_random_ord_seed is
    l_actual ut3.ut_varchar2_list;
  begin
    select * bulk collect into l_actual
      from table ( ut3.ut.run( 'ut3_tester_helper.test_package_1', a_random_test_order_seed => 123456789 ) );

    ut.expect( ut3_tester_helper.main_helper.table_to_clob(l_actual) ).to_be_like( q'[%Tests were executed with random order seed '123456789'.%]' );
  end;

  procedure run_with_random_order_seed is
    l_expected ut3.ut_varchar2_list;
    l_actual   ut3.ut_varchar2_list;
  begin

    select * bulk collect into l_expected
      from table ( ut3.ut.run( 'ut3_tester_helper.test_package_1', a_random_test_order_seed => 3 ) );
    select * bulk collect into l_actual
      from table ( ut3.ut.run( 'ut3_tester_helper.test_package_1', a_random_test_order_seed => 3 ) );

    remove_time_from_results(l_actual);
    remove_time_from_results(l_expected);
    l_actual.delete(l_actual.count);
    l_expected.delete(l_expected.count);

    ut.expect(anydata.convertCollection(l_actual)).to_equal(anydata.convertCollection(l_expected));
  end;
  
  procedure test_run_by_one_tag is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'suite1test1');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );  
  end;

  procedure suite_run_by_one_tag is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'suite2');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).not_to_be_like( '%test_package_1.%executed%' );
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_2%' );
    ut.expect( l_results ).to_be_like( '%test_package_2.%executed%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3.%executed%' );  
  end;
 
  procedure two_test_run_by_one_tag is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'test2');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).not_to_be_like( '%test_package_1.%executed%' );
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_2%' );
    ut.expect( l_results ).to_be_like( '%test_package_2.%executed%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3.%executed%' );  
  end;
  
  procedure all_suites_run_by_one_tag is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'helper');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_2%' );
    ut.expect( l_results ).to_be_like( '%test_package_3%' ); 
  end; 
  
  procedure two_test_run_by_two_tags is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'subtest1,subtest2');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_1.test2%' ); 
    ut.expect( l_results ).not_to_be_like( '%test_package_2.test2%' ); 
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' ); 
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );  
  end;
  
  procedure suite_with_children_tag  is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'suite1');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );  
  end;
  
  procedure suite_with_tag_parent is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'suite2');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );  
  end;
  
  procedure test_nonexists_tag is
    l_results clob;
    l_exp_message varchar2(4000);
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'nonexisting');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    ut.expect( l_results ).not_to_be_like( '%test_package_1%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' ); 
  end; 
  
  procedure test_duplicate_tag is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'suite1test1,suite1test1');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' ); 
  end;
  
  procedure suite_duplicate_tag is
    l_results clob;
  begin
    ut3_tester_helper.run_helper.run(a_tags => 'suite1,suite1');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' ); 
  end;  
  
  procedure run_proc_pkg_name_tag is
    l_results clob;
  begin
    ut3.ut.run('ut3_tester_helper.test_package_1',a_tags => 'suite1test1');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_1.test1%executed%' ); 
    ut.expect( l_results ).not_to_be_like( '%test_package_1.test2%' ); 
    ut.expect( l_results ).not_to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );
  end;
  
  procedure run_pkg_name_file_list_tag is
    l_results clob;
  begin
    ut3.ut.run('ut3_tester_helper.test_package_1',a_tags => 'suite1test1');
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%test_package_1%' );
    ut.expect( l_results ).to_be_like( '%test_package_1.test1%executed%' ); 
    ut.expect( l_results ).not_to_be_like( '%test_package_1.test2%' ); 
    ut.expect( l_results ).not_to_be_like( '%test_package_2%' );
    ut.expect( l_results ).not_to_be_like( '%test_package_3%' );
  end;
  
  procedure run_proc_path_list_tag is
    l_results clob;
  begin
     ut3.ut.run(
       'ut3_tester_helper.test_package_1',
       ut3.ut_sonar_test_reporter(), a_source_files => ut3.ut_varchar2_list(),a_tags => 'suite1',
       a_test_files => ut3.ut_varchar2_list('tests/ut3_tester_helper.test_package_1.pkb',
         'tests/ut3_tester_helper.test_package_2.pkb',
         'tests/ut3_tester_helper.test_package_3.pkb')
       );
    l_results :=  ut3_tester_helper.main_helper.get_dbms_output_as_clob();
    --Assert
    ut.expect( l_results ).to_be_like( '%tests/ut3_tester_helper.test_package_1.pkb%' );
    ut.expect( l_results ).not_to_be_like( '%tests/ut3_tester_helper.test_package_2.pkb%' );
    ut.expect( l_results ).not_to_be_like( '%tests/ut3_tester_helper.test_package_3.pkb%' );
  end;

  procedure tag_run_func_no_params is
    l_results   ut3.ut_varchar2_list;
  begin
    l_results := ut3_tester_helper.run_helper.run(a_tags => 'helper');
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%test_package_2%test_package_3%' );
  end;

  procedure tag_run_func_pkg_name is
    l_results   ut3.ut_varchar2_list;
  begin
    select * bulk collect into l_results from table (ut3.ut.run('ut3_tester_helper.test_package_1', a_tags => 'suite1test1'));
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1.test1%executed%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%test_package_1.test2%executed%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%test_package_2%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%test_package_3%' );
  end;

  procedure tag_run_func_path_list is
    l_results   ut3.ut_varchar2_list;
  begin
    l_results := ut3_tester_helper.run_helper.run(ut3.ut_varchar2_list(':tests.test_package_1',':tests'),a_tags => 'suite1test1,suite2test1');
    --Assert
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_2%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_1.test1%executed%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%test_package_1.test2%executed%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).to_be_like( '%test_package_2.test1%executed%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%test_package_2.test2%executed%' );
    ut.expect(  ut3_tester_helper.main_helper.table_to_clob(l_results) ).not_to_be_like( '%test_package_3%' );
  end;

  procedure set_application_info is
  begin
    dbms_application_info.set_module( gc_module, gc_action );
    dbms_application_info.set_client_info( gc_client_info );
  end;

  procedure create_context_test_suite is
    pragma autonomous_transaction;
  begin
    execute immediate q'[
      create or replace package check_context is
        --%suite(Suite description)
        --%suitepath(some.suite.path)

        --%beforeall
        procedure before_suite;

        --%context(some_context)

          --%displayname(context description)

          --%beforeall
          procedure before_context;

          --%beforeeach
          procedure before_each_test;

          --%test(Some test description)
          --%beforetest(before_test)
          --%aftertest(after_test)
          procedure the_test;
          procedure before_test;
          procedure after_test;

          --%aftereach
          procedure after_each_test;

          --%afterall
          procedure after_context;

        --%endcontext


        --%afterall
        procedure after_suite;

      end;]';
    execute immediate q'[
      create or replace package body check_context is

        procedure print_context( a_procedure_name varchar2 ) is
          l_results      ut_varchar2_rows;
          l_module       varchar2(32767);
          l_action       varchar2(32767);
          l_client_info  varchar2(32767);
        begin
          select attribute||'='||value
          bulk collect into l_results
           from session_context where namespace = 'UT3_INFO'
          order by attribute;
          for i in 1 .. l_results.count loop
            dbms_output.put_line( upper(a_procedure_name) ||':'|| l_results(i) );
          end loop;
          dbms_application_info.read_module( l_module, l_action );
          dbms_application_info.read_client_info( l_client_info );

          dbms_output.put_line( 'APPLICATION_INFO:MODULE=' || l_module );
          dbms_output.put_line( 'APPLICATION_INFO:ACTION=' || l_action );
          dbms_output.put_line( 'APPLICATION_INFO:CLIENT_INFO=' || l_client_info );
        end;

        procedure before_suite is
        begin
          print_context('before_suite');
        end;

        procedure before_context is
        begin
          print_context('before_context');
        end;

        procedure before_each_test is
        begin
          print_context('before_each_test');
        end;

        procedure the_test is
        begin
          print_context('the_test');
        end;

        procedure before_test is
        begin
          print_context('before_test');
        end;

        procedure after_test is
        begin
          print_context('after_test');
        end;

        procedure after_each_test is
        begin
          print_context('after_each_test');
        end;

        procedure after_context is
        begin
          print_context('after_context');
        end;

        procedure after_suite is
        begin
          print_context('after_suite');
        end;

      end;]';
  end;

  procedure drop_context_test_suite is
    pragma autonomous_transaction;
  begin
    execute immediate q'[drop package check_context]';
  end;

  procedure run_context_test_suite is
    l_lines  ut3.ut_varchar2_list;
  begin
    select * bulk collect into l_lines from table(ut3.ut.run('check_context'));
    g_context_test_results := ut3_tester_helper.main_helper.table_to_clob(l_lines);
  end;


  procedure sys_ctx_on_suite_beforeall is
  begin
    ut.expect(g_context_test_results).to_be_like(
      '%BEFORE_SUITE:CURRENT_EXECUTABLE_NAME='||gc_owner||'.check_context.before_suite'
        ||'%BEFORE_SUITE:CURRENT_EXECUTABLE_TYPE=beforeall'
        ||'%BEFORE_SUITE:RUN_PATHS=check_context'
        ||'%BEFORE_SUITE:SUITE_DESCRIPTION=Suite description'
        ||'%BEFORE_SUITE:SUITE_PACKAGE='||gc_owner||'.check_context'
        ||'%BEFORE_SUITE:SUITE_PATH=some.suite.path.check_context'
        ||'%BEFORE_SUITE:SUITE_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%APPLICATION_INFO:MODULE=utPLSQL'
        ||'%APPLICATION_INFO:ACTION=check_context'
        ||'%APPLICATION_INFO:CLIENT_INFO=before_suite%'
      );
    ut.expect(g_context_test_results).not_to_be_like('%BEFORE_SUITE:CONTEXT_%');
    ut.expect(g_context_test_results).not_to_be_like('%BEFORE_SUITE:TEST_%');
  end;

  procedure sys_ctx_on_context_beforeall is
  begin
    ut.expect(g_context_test_results).to_be_like(
      '%BEFORE_CONTEXT:CONTEXT_DESCRIPTION=context description'
        ||'%BEFORE_CONTEXT:CONTEXT_NAME=some_context'
        ||'%BEFORE_CONTEXT:CONTEXT_PATH=some.suite.path.check_context.some_context'
        ||'%BEFORE_CONTEXT:CONTEXT_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%BEFORE_CONTEXT:CURRENT_EXECUTABLE_NAME='||gc_owner||'.check_context.before_context'
        ||'%BEFORE_CONTEXT:CURRENT_EXECUTABLE_TYPE=beforeall'
        ||'%BEFORE_CONTEXT:RUN_PATHS=check_context'
        ||'%BEFORE_CONTEXT:SUITE_DESCRIPTION=Suite description'
        ||'%BEFORE_CONTEXT:SUITE_PACKAGE='||gc_owner||'.check_context'
        ||'%BEFORE_CONTEXT:SUITE_PATH=some.suite.path.check_context'
        ||'%BEFORE_CONTEXT:SUITE_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%APPLICATION_INFO:MODULE=utPLSQL'
        ||'%APPLICATION_INFO:ACTION=check_context'
        ||'%APPLICATION_INFO:CLIENT_INFO=before_context%'
      );
    ut.expect(g_context_test_results).not_to_be_like('%BEFORE_CONTEXT:TEST_%');
  end;

  procedure sys_ctx_on_beforeeach is
  begin
    ut.expect(g_context_test_results).to_be_like(
      '%BEFORE_EACH_TEST:CONTEXT_DESCRIPTION=context description'
        ||'%BEFORE_EACH_TEST:CONTEXT_NAME=some_context'
        ||'%BEFORE_EACH_TEST:CONTEXT_PATH=some.suite.path.check_context.some_context'
        ||'%BEFORE_EACH_TEST:CONTEXT_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%BEFORE_EACH_TEST:CURRENT_EXECUTABLE_NAME='||gc_owner||'.check_context.before_each_test'
        ||'%BEFORE_EACH_TEST:CURRENT_EXECUTABLE_TYPE=beforeeach'
        ||'%BEFORE_EACH_TEST:RUN_PATHS=check_context'
        ||'%BEFORE_EACH_TEST:SUITE_DESCRIPTION=Suite description'
        ||'%BEFORE_EACH_TEST:SUITE_PACKAGE='||gc_owner||'.check_context'
        ||'%BEFORE_EACH_TEST:SUITE_PATH=some.suite.path.check_context'
        ||'%BEFORE_EACH_TEST:SUITE_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%BEFORE_EACH_TEST:TEST_DESCRIPTION=Some test description'
        ||'%BEFORE_EACH_TEST:TEST_NAME='||gc_owner||'.check_context.the_test'
        ||'%BEFORE_EACH_TEST:TEST_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%APPLICATION_INFO:MODULE=utPLSQL'
        ||'%APPLICATION_INFO:ACTION=check_context'
        ||'%APPLICATION_INFO:CLIENT_INFO=before_each_test%'
      );
  end;

  procedure sys_ctx_on_beforetest is
  begin
    ut.expect(g_context_test_results).to_be_like(
      '%BEFORE_TEST:CONTEXT_DESCRIPTION=context description'
        ||'%BEFORE_TEST:CONTEXT_NAME=some_context'
        ||'%BEFORE_TEST:CONTEXT_PATH=some.suite.path.check_context.some_context'
        ||'%BEFORE_TEST:CONTEXT_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%BEFORE_TEST:CURRENT_EXECUTABLE_NAME='||gc_owner||'.check_context.before_test'
        ||'%BEFORE_TEST:CURRENT_EXECUTABLE_TYPE=beforetest'
        ||'%BEFORE_TEST:RUN_PATHS=check_context'
        ||'%BEFORE_TEST:SUITE_DESCRIPTION=Suite description'
        ||'%BEFORE_TEST:SUITE_PACKAGE='||gc_owner||'.check_context'
        ||'%BEFORE_TEST:SUITE_PATH=some.suite.path.check_context'
        ||'%BEFORE_TEST:SUITE_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%BEFORE_TEST:TEST_DESCRIPTION=Some test description'
        ||'%BEFORE_TEST:TEST_NAME='||gc_owner||'.check_context.the_test'
        ||'%BEFORE_TEST:TEST_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%APPLICATION_INFO:MODULE=utPLSQL'
        ||'%APPLICATION_INFO:ACTION=check_context'
        ||'%APPLICATION_INFO:CLIENT_INFO=before_test%'
      );
  end;

  procedure sys_ctx_on_test is
  begin
    ut.expect(g_context_test_results).to_be_like(
      '%THE_TEST:CONTEXT_DESCRIPTION=context description'
        ||'%THE_TEST:CONTEXT_NAME=some_context'
        ||'%THE_TEST:CONTEXT_PATH=some.suite.path.check_context.some_context'
        ||'%THE_TEST:CONTEXT_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%THE_TEST:CURRENT_EXECUTABLE_NAME='||gc_owner||'.check_context.the_test'
        ||'%THE_TEST:CURRENT_EXECUTABLE_TYPE=test'
        ||'%THE_TEST:RUN_PATHS=check_context'
        ||'%THE_TEST:SUITE_DESCRIPTION=Suite description'
        ||'%THE_TEST:SUITE_PACKAGE='||gc_owner||'.check_context'
        ||'%THE_TEST:SUITE_PATH=some.suite.path.check_context'
        ||'%THE_TEST:SUITE_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%THE_TEST:TEST_DESCRIPTION=Some test description'
        ||'%THE_TEST:TEST_NAME='||gc_owner||'.check_context.the_test'
        ||'%THE_TEST:TEST_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%APPLICATION_INFO:MODULE=utPLSQL'
        ||'%APPLICATION_INFO:ACTION=check_context'
        ||'%APPLICATION_INFO:CLIENT_INFO=the_test%'
      );
  end;

  procedure sys_ctx_on_aftertest is
  begin
    ut.expect(g_context_test_results).to_be_like(
      '%AFTER_TEST:CONTEXT_DESCRIPTION=context description'
        ||'%AFTER_TEST:CONTEXT_NAME=some_context'
        ||'%AFTER_TEST:CONTEXT_PATH=some.suite.path.check_context.some_context'
        ||'%AFTER_TEST:CONTEXT_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%AFTER_TEST:CURRENT_EXECUTABLE_NAME='||gc_owner||'.check_context.after_test'
        ||'%AFTER_TEST:CURRENT_EXECUTABLE_TYPE=aftertest'
        ||'%AFTER_TEST:RUN_PATHS=check_context'
        ||'%AFTER_TEST:SUITE_DESCRIPTION=Suite description'
        ||'%AFTER_TEST:SUITE_PACKAGE='||gc_owner||'.check_context'
        ||'%AFTER_TEST:SUITE_PATH=some.suite.path.check_context'
        ||'%AFTER_TEST:SUITE_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%AFTER_TEST:TEST_DESCRIPTION=Some test description'
        ||'%AFTER_TEST:TEST_NAME='||gc_owner||'.check_context.the_test'
        ||'%AFTER_TEST:TEST_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%APPLICATION_INFO:MODULE=utPLSQL'
        ||'%APPLICATION_INFO:ACTION=check_context'
        ||'%APPLICATION_INFO:CLIENT_INFO=after_test%'
      );
  end;

  procedure sys_ctx_on_aftereach is
  begin
    ut.expect(g_context_test_results).to_be_like(
      '%AFTER_EACH_TEST:CONTEXT_DESCRIPTION=context description'
        ||'%AFTER_EACH_TEST:CONTEXT_NAME=some_context'
        ||'%AFTER_EACH_TEST:CONTEXT_PATH=some.suite.path.check_context.some_context'
        ||'%AFTER_EACH_TEST:CONTEXT_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%AFTER_EACH_TEST:CURRENT_EXECUTABLE_NAME='||gc_owner||'.check_context.after_each_test'
        ||'%AFTER_EACH_TEST:CURRENT_EXECUTABLE_TYPE=aftereach'
        ||'%AFTER_EACH_TEST:RUN_PATHS=check_context'
        ||'%AFTER_EACH_TEST:SUITE_DESCRIPTION=Suite description'
        ||'%AFTER_EACH_TEST:SUITE_PACKAGE='||gc_owner||'.check_context'
        ||'%AFTER_EACH_TEST:SUITE_PATH=some.suite.path.check_context'
        ||'%AFTER_EACH_TEST:SUITE_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%AFTER_EACH_TEST:TEST_DESCRIPTION=Some test description'
        ||'%AFTER_EACH_TEST:TEST_NAME='||gc_owner||'.check_context.the_test'
        ||'%AFTER_EACH_TEST:TEST_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%APPLICATION_INFO:MODULE=utPLSQL'
        ||'%APPLICATION_INFO:ACTION=check_context'
        ||'%APPLICATION_INFO:CLIENT_INFO=after_each_test%'
      );
  end;

  procedure sys_ctx_on_context_afterall is
  begin
    ut.expect(g_context_test_results).to_be_like(
      '%AFTER_CONTEXT:CONTEXT_DESCRIPTION=context description'
        ||'%AFTER_CONTEXT:CONTEXT_NAME=some_context'
        ||'%AFTER_CONTEXT:CONTEXT_PATH=some.suite.path.check_context.some_context'
        ||'%AFTER_CONTEXT:CONTEXT_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%AFTER_CONTEXT:CURRENT_EXECUTABLE_NAME='||gc_owner||'.check_context.after_context'
        ||'%AFTER_CONTEXT:CURRENT_EXECUTABLE_TYPE=afterall'
        ||'%AFTER_CONTEXT:RUN_PATHS=check_context'
        ||'%AFTER_CONTEXT:SUITE_DESCRIPTION=Suite description'
        ||'%AFTER_CONTEXT:SUITE_PACKAGE='||gc_owner||'.check_context'
        ||'%AFTER_CONTEXT:SUITE_PATH=some.suite.path.check_context'
        ||'%AFTER_CONTEXT:SUITE_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%APPLICATION_INFO:MODULE=utPLSQL'
        ||'%APPLICATION_INFO:ACTION=check_context'
        ||'%APPLICATION_INFO:CLIENT_INFO=after_context%'
      );
    ut.expect(g_context_test_results).not_to_be_like('%AFTER_CONTEXT:TEST_%');
  end;

  procedure sys_ctx_on_suite_afterall is
  begin
    ut.expect(g_context_test_results).to_be_like(
      '%AFTER_SUITE:CURRENT_EXECUTABLE_NAME='||gc_owner||'.check_context.after_suite'
        ||'%AFTER_SUITE:CURRENT_EXECUTABLE_TYPE=afterall'
        ||'%AFTER_SUITE:RUN_PATHS=check_context'
        ||'%AFTER_SUITE:SUITE_DESCRIPTION=Suite description'
        ||'%AFTER_SUITE:SUITE_PACKAGE='||gc_owner||'.check_context'
        ||'%AFTER_SUITE:SUITE_PATH=some.suite.path.check_context'
        ||'%AFTER_SUITE:SUITE_START_TIME='||to_char(current_timestamp,'yyyy-mm-dd"T"hh24:mi')
        ||'%APPLICATION_INFO:MODULE=utPLSQL'
        ||'%APPLICATION_INFO:ACTION=check_context'
        ||'%APPLICATION_INFO:CLIENT_INFO=after_suite%'
      );
    ut.expect(g_context_test_results).not_to_be_like('%AFTER_SUITE:CONTEXT_%');
    ut.expect(g_context_test_results).not_to_be_like('%AFTER_SUITE:TEST_%');
  end;

  procedure sys_ctx_clear_after_run is
    l_actual  sys_refcursor;
  begin
    open l_actual for
      select attribute||'='||value
        from session_context where namespace = 'UT3_INFO';

    ut.expect(l_actual).to_be_empty();
  end;

  procedure app_info_restore_after_run is
    l_module       varchar2(32767);
    l_action       varchar2(32767);
    l_client_info  varchar2(32767);
  begin
    dbms_application_info.read_module( l_module, l_action );
    dbms_application_info.read_client_info( l_client_info );

    ut.expect(l_module).to_equal(gc_module);
    ut.expect(l_action).to_equal(gc_action);
    --Disabled as it can't be tested.
    --UT3_LATEST_RELEASE is also setting the client_info on each procedure
    -- ut.expect(l_client_info).to_equal(gc_client_info);
  end;

end;
/
