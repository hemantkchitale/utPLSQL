create or replace package body ut_suite_cache_manager is
  /*
  utPLSQL - Version 3
  Copyright 2016 - 2019 utPLSQL Project

  Licensed under the Apache License, Version 2.0 (the "License"):
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */

  /*
  * Private code
  */

  gc_get_cache_suite_sql    constant varchar2(32767) :=
    q'[with
      suite_items as (
        select  /*+ cardinality(c 100) */ value(c) as obj
          from ut_suite_cache c
         where 1 = 1
               and c.object_owner = :l_object_owner
               and ( {:path:}
                     and {:object_name:}
                     and {:procedure_name:}
                   )
        )
      ),
      {:tags:}
      suitepaths as (
        select distinct substr(c.obj.path,1,instr(c.obj.path,'.',-1)-1) as suitepath,
                        c.obj.path as path,
                        c.obj.object_owner as object_owner
          from {:suite_item_name:} c
         where c.obj.self_type = 'UT_SUITE'
      ),
        gen as (
        select rownum as pos
          from xmltable('1 to 20')
      ),
      suitepath_part AS (
        select distinct
                        substr(b.suitepath, 1, instr(b.suitepath || '.', '.', 1, g.pos) -1) as path,
                        object_owner
          from suitepaths b
               join gen g
                 on g.pos <= regexp_count(b.suitepath, '\w+')
      ),
      logical_suite_data as (
        select 'UT_LOGICAL_SUITE' as self_type, p.path, p.object_owner,
               upper( substr(p.path, instr( p.path, '.', -1 ) + 1 ) ) as object_name,
               cast(null as ut_executables) as x,
               cast(null as ut_integer_list) as y,
               cast(null as ut_executable_test) as z
          from suitepath_part p
         where p.path
           not in (select s.path from suitepaths s)
      ),
      logical_suites as (
        select ut_suite_cache_row(
                 null,
                 s.self_type, s.path, s.object_owner, s.object_name,
                 s.object_name, null, null, null, null, 0,
                 ut_varchar2_rows(),
                 s.x, s.x, s.x, s.x, s.x, s.x,
                 s.y, null, s.z
               ) as obj
          from logical_suite_data s
      ),
      items as (
        select obj from {:suite_item_name:}
        union all
        select obj from logical_suites
      )
    select c.obj
      from items c
     order by c.obj.object_owner,{:random_seed:}]';

  function get_missing_cache_objects(a_object_owner varchar2) return ut_varchar2_rows is
    l_result       ut_varchar2_rows;
    l_data         ut_annotation_objs_cache_info;
  begin
    l_data := ut_annotation_cache_manager.get_annotations_objects_info(a_object_owner, 'PACKAGE');

    select i.object_name
           bulk collect into l_result
      from ut_suite_cache_package i
     where not exists (
       select 1 from table(l_data) o
        where o.object_owner = i.object_owner
          and o.object_name = i.object_name
          and o.object_type = 'PACKAGE'
       )
       and i.object_owner = a_object_owner;
    return l_result;
  end;


  function get_path_sql(a_path in varchar2) return varchar2 is
  begin
    return case when a_path is not null then q'[
                      :l_path||'.' like c.path || '.%' /*all children and self*/
                     or ( c.path||'.' like :l_path || '.%'  --all parents
                            ]'
           else ' :l_path is null  and ( :l_path is null ' end;
  end;

  function get_object_name_sql(a_object_name in varchar2) return varchar2 is
  begin
    return case when a_object_name is not null
      then ' c.object_name = :a_object_name '
           else ' :a_object_name is null' end;
  end;

  function get_procedure_name_sql(a_procedure_name in varchar2) return varchar2 is
  begin
    return case when a_procedure_name is not null
      then ' c.name = :a_procedure_name'
           else ' :a_procedure_name is null' end;
  end;

  function get_tags_sql(a_tags_count in integer) return varchar2 is
  begin
    return case when a_tags_count > 0 then
      q'[filter_tags as (
        select c.obj.path as path
          from suite_items c
         where c.obj.tags multiset intersect :a_tag_list is not empty
      ),
       suite_items_tags as (
       select c.*
         from suite_items c
        where exists (
          select 1 from filter_tags t
           where t.path||'.' like c.obj.path || '.%' /*all children and self*/
              or c.obj.path||'.' like t.path || '.%'  --all parents
          )
       ),]'
           else
             q'[dummy as (select 'x' from dual where :a_tag_list is null ),]'
           end;
  end;

  function get_random_seed_sql(a_random_seed positive) return varchar2 is
  begin
    return case
           when a_random_seed is null then q'[
              replace(
                case
                  when c.obj.self_type in ( 'UT_TEST' )
                    then substr(c.obj.path, 1, instr(c.obj.path, '.', -1) )
                    else c.obj.path
                end, '.', chr(0)
              ) desc nulls last,
              c.obj.object_name desc,
              c.obj.line_no,
              :a_random_seed]'
           else
             ' ut_runner.hash_suite_path(
               c.obj.path, :a_random_seed
             ) desc nulls last'
           end;
  end;



  /*
  * Public code
  */
  function get_cached_suite_rows(
    a_object_owner     varchar2,
    a_path             varchar2 := null,
    a_object_name      varchar2 := null,
    a_procedure_name   varchar2 := null,
    a_random_seed      positive := null,
    a_tags             ut_varchar2_rows := null
  ) return ut_suite_cache_rows is
    l_path            varchar2(4000);
    l_results         ut_suite_cache_rows := ut_suite_cache_rows();
    l_sql             varchar2(32767);
    l_suite_item_name varchar2(20);
    l_tags            ut_varchar2_rows := coalesce(a_tags,ut_varchar2_rows());
    l_object_owner    varchar2(250) := ut_utils.qualified_sql_name(a_object_owner);
    l_object_name     varchar2(250) := ut_utils.qualified_sql_name(a_object_name);
    l_procedure_name  varchar2(250) := ut_utils.qualified_sql_name(a_procedure_name);
  begin
    if a_path is null and a_object_name is not null then
      select min(c.path)
             into l_path
        from ut_suite_cache c
       where c.object_owner = upper(l_object_owner)
         and c.object_name = upper(l_object_name)
         and c.name = nvl(upper(l_procedure_name), c.name);
      else
        l_path := lower(ut_utils.qualified_sql_name(a_path));
      end if;
    l_suite_item_name := case when l_tags.count > 0 then 'suite_items_tags' else 'suite_items' end;

    l_sql := gc_get_cache_suite_sql;
    l_sql := replace(l_sql,'{:suite_item_name:}',l_suite_item_name);
    l_sql := replace(l_sql,'{:object_owner:}',upper(l_object_owner));
    l_sql := replace(l_sql,'{:path:}',get_path_sql(l_path));
    l_sql := replace(l_sql,'{:object_name:}',get_object_name_sql(l_object_name));
    l_sql := replace(l_sql,'{:procedure_name:}',get_procedure_name_sql(l_procedure_name));
    l_sql := replace(l_sql,'{:tags:}',get_tags_sql(l_tags.count));
    l_sql := replace(l_sql,'{:random_seed:}',get_random_seed_sql(a_random_seed));

    ut_event_manager.trigger_event(ut_event_manager.gc_debug, ut_key_anyvalues().put('l_sql',l_sql) );

    execute immediate l_sql
      bulk collect into l_results
      using upper(l_object_owner), l_path, l_path, upper(a_object_name), upper(a_procedure_name), l_tags, a_random_seed;
    return l_results;
  end;

  function get_schema_parse_time(a_schema_name varchar2) return timestamp result_cache is
    l_cache_parse_time timestamp;
  begin
    select min(t.parse_time)
      into l_cache_parse_time
      from ut_suite_cache_schema t
     where object_owner = a_schema_name;
    return l_cache_parse_time;
  end;

  procedure save_object_cache(
    a_object_owner varchar2,
    a_object_name  varchar2,
    a_parse_time   timestamp,
    a_suite_items ut_suite_items
  ) is
    pragma autonomous_transaction;
    l_cached_parse_time timestamp;
    l_object_owner      varchar2(250) := upper(a_object_owner);
    l_object_name       varchar2(250) := upper(a_object_name);
  begin
    if a_suite_items is not null and a_suite_items.count = 0 then

      delete from ut_suite_cache t
       where t.object_owner = l_object_owner
         and t.object_name = l_object_name;

      delete from ut_suite_cache_package t
       where t.object_owner = l_object_owner
         and t.object_name = l_object_name;

    else

      select min(parse_time)
        into l_cached_parse_time
        from ut_suite_cache_package t
       where t.object_name = l_object_name
         and t.object_owner = l_object_owner;

      if a_parse_time > l_cached_parse_time or l_cached_parse_time is null then

        update ut_suite_cache_schema t
           set t.parse_time = a_parse_time
         where object_owner = l_object_owner;

        if sql%rowcount = 0 then
          insert into ut_suite_cache_schema
            (object_owner, parse_time)
          values (l_object_owner, a_parse_time);
        end if;

        update ut_suite_cache_package t
           set t.parse_time = a_parse_time
         where t.object_owner = l_object_owner
           and t.object_name = l_object_name;

        if sql%rowcount = 0 then
          insert into ut_suite_cache_package
            (object_owner, object_name, parse_time)
          values (l_object_owner, l_object_name, a_parse_time );
        end if;

        delete from ut_suite_cache t
        where t.object_owner = l_object_owner
          and t.object_name  = l_object_name;

        insert into ut_suite_cache t
            (
                id, self_type, path, object_owner, object_name, name,
                line_no, parse_time, description,
                rollback_type, disabled_flag, warnings,
                before_all_list, after_all_list,
                before_each_list, after_each_list,
                before_test_list, after_test_list,
                expected_error_codes, tags,
                item
            )
          with suites as (
               select treat(value(x) as ut_suite) i
                 from table(a_suite_items) x
                where x.self_type in( 'UT_SUITE', 'UT_SUITE_CONTEXT' ) )
          select ut_suite_cache_seq.nextval, s.i.self_type as self_type, s.i.path as path,
                 upper(s.i.object_owner) as object_owner, upper(s.i.object_name) as object_name, upper(s.i.name) as name,
                 s.i.line_no as line_no, s.i.parse_time as parse_time, s.i.description as description,
                 s.i.rollback_type as rollback_type, s.i.disabled_flag as disabled_flag, s.i.warnings as warnings,
                 s.i.before_all_list as before_all_list, s.i.after_all_list as after_all_list,
                 null before_each_list, null after_each_list,
                 null before_test_list, null after_test_list,
                 null expected_error_codes, s.i.tags tags,
                 null item
          from suites s;

        insert into ut_suite_cache t
          (
            id, self_type, path, object_owner, object_name, name,
            line_no, parse_time, description,
            rollback_type, disabled_flag, warnings,
            before_all_list, after_all_list,
            before_each_list, after_each_list,
            before_test_list, after_test_list,
            expected_error_codes, tags,
            item
          )
          with tests as (
               select treat(value(x) as ut_test) t
                 from table ( a_suite_items ) x
                where x.self_type in ( 'UT_TEST' ) )
        select ut_suite_cache_seq.nextval, s.t.self_type as self_type, s.t.path as path,
               upper(s.t.object_owner) as object_owner, upper(s.t.object_name) as object_name, upper(s.t.name) as name,
               s.t.line_no as line_no, s.t.parse_time as parse_time, s.t.description as description,
               s.t.rollback_type as rollback_type, s.t.disabled_flag as disabled_flag, s.t.warnings as warnings,
               null before_all_list, null after_all_list,
               s.t.before_each_list as before_each_list, s.t.after_each_list as after_each_list,
               s.t.before_test_list as before_test_list, s.t.after_test_list as after_test_list,
               s.t.expected_error_codes as expected_error_codes, s.t.tags as test_tags,
               s.t.item as item
          from tests s;

      end if;
    end if;
    commit;
  end;

  procedure remove_missing_objs_from_cache(a_schema_name varchar2) is
    l_objects ut_varchar2_rows;
    pragma autonomous_transaction;
  begin
    l_objects := get_missing_cache_objects(a_schema_name);
    delete from ut_suite_cache i
     where i.object_owner = a_schema_name
       and i.object_name in ( select column_value from table (l_objects) );

    delete from ut_suite_cache_package i
     where i.object_owner = a_schema_name
       and i.object_name in ( select column_value from table (l_objects) );

    commit;
  end;

  function get_cached_suite_info(
    a_object_owner     varchar2,
    a_object_name      varchar2
  ) return ut_suite_items_info is
    l_cache_rows   ut_suite_cache_rows;
    l_results      ut_suite_items_info;
  begin
    l_cache_rows := get_cached_suite_rows( a_object_owner => a_object_owner, a_object_name =>a_object_name );
    select ut_suite_item_info(
             c.object_owner, c.object_name, c.name,
             c.description, c.self_type, c.line_no,
             c.path, c.disabled_flag, c.tags
             )
      bulk collect into l_results
      from table(l_cache_rows) c;

    return l_results;
  end;

  function get_cached_packages(
    a_schema_names ut_varchar2_rows
  ) return ut_object_names is
    l_results ut_object_names;
  begin
    select ut_object_name( c.object_owner, c.object_name )
      bulk collect into l_results
      from ut_suite_cache_package c
      join table ( a_schema_names ) s
        on c.object_owner = upper(s.column_value);
    return l_results;
  end;

  function suite_item_exists(
    a_owner_name     varchar2,
    a_package_name   varchar2,
    a_procedure_name varchar2
  ) return boolean is
    l_count integer;
  begin
    if a_procedure_name is not null then
      select count( 1 ) into l_count from dual
       where exists(
               select 1
                 from ut_suite_cache c
                where c.object_owner = a_owner_name
                  and c.object_name = a_package_name
                  and c.name = a_procedure_name
               );
    elsif a_package_name is not null then
      select count( 1 ) into l_count from dual
       where exists(
               select 1
                 from ut_suite_cache c
                where c.object_owner = a_owner_name
                  and c.object_name = a_package_name
               );
    else
      select count( 1 ) into l_count from dual
       where exists(
               select 1
                 from ut_suite_cache c
                where c.object_owner = a_owner_name
               );
    end if;

    return l_count > 0;
  end;

end ut_suite_cache_manager;
/
