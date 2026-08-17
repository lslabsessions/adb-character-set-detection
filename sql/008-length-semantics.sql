/*
 Explore character width and BYTE vs CHAR length semantics when moving from
 a single-byte character set such as WE8MSWIN1252 to AL32UTF8
*/

set serveroutput on;

prompt === DATABASE CHARACTER SETS ===

select parameter,
       value
from nls_database_parameters
where parameter in (
    'NLS_CHARACTERSET',
    'NLS_NCHAR_CHARACTERSET'
)
order by parameter;


prompt
prompt === MAXIMUM CHARACTER SIZE ===

select
    utl_i18n.get_max_character_size('WE8MSWIN1252')
        as win1252_max_bytes,
    utl_i18n.get_max_character_size('AL32UTF8')
        as al32utf8_max_bytes
from dual;


prompt
prompt === CHARACTER LENGTH VS BYTE LENGTH ===

select
    length('Desassociação')  as character_length,
    lengthb('Desassociação') as byte_length
from dual;


prompt
prompt === SESSION DEFAULT ===

select parameter,
       value
from nls_session_parameters
where parameter = 'NLS_LENGTH_SEMANTICS';


begin
    execute immediate 'drop table length_semantics_demo purge';
exception
    when others then
        if sqlcode != -942 then
            raise;
        end if;
end;
/


create table length_semantics_demo (
    value_byte varchar2(13 byte),
    value_char varchar2(13 char)
);


prompt
prompt === INSERT INTO VARCHAR2(13 BYTE) ===

begin
    insert into length_semantics_demo(value_byte)
    values ('Desassociação');

    dbms_output.put_line(
        'Unexpected result: insert into VALUE_BYTE succeeded.'
    );

    rollback;
exception
    when value_error then
        dbms_output.put_line(
            'Expected failure: ' || sqlerrm
        );
    when others then
        if sqlcode = -12899 then
            dbms_output.put_line(
                'Expected failure: ' || sqlerrm
            );
        else
            raise;
        end if;
end;
/


prompt
prompt === INSERT INTO VARCHAR2(13 CHAR) ===

insert into length_semantics_demo(value_char)
values ('Desassociação');

commit;


select
    value_char,
    length(value_char)  as character_length,
    lengthb(value_char) as byte_length
from length_semantics_demo;


prompt
prompt === COLUMN METADATA ===

select
    column_name,
    data_length,
    char_length,
    char_used
from user_tab_columns
where table_name = 'LENGTH_SEMANTICS_DEMO'
order by column_id;


drop table length_semantics_demo purge;


prompt
prompt === OPTIONAL SESSION DEFAULT ===
prompt The session default can be changed with:
prompt ALTER SESSION SET NLS_LENGTH_SEMANTICS = CHAR;
prompt
prompt Explicit BYTE or CHAR qualifiers in DDL override the session default.
