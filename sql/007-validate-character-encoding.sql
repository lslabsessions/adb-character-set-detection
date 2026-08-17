/*
 Demonstrate VALIDATE_CHARACTER_ENCODING with an unpaired Unicode surrogate.

 In the lab environment:
   NLS_CHARACTERSET       = AL32UTF8
   NLS_NCHAR_CHARACTERSET = AL16UTF16

 Oracle considers an unpaired surrogate invalid in Unicode character sets.
 The function returns 0 when data is valid and the first invalid offset
 otherwise.

 For VARCHAR2/NVARCHAR2 the returned offset is a byte offset.
 For CLOB/NCLOB the returned offset is a character offset.
 
 
 DBMS_LOB.SUBSTR is used only to make the CLOB content displayable as a VARCHAR2. 
 During that step, the unpaired surrogate cannot be represented as valid AL32UTF8 
 character data and is shown as the Unicode replacement character U+FFFD. 
 The validation itself is performed directly on the CLOB before this display conversion, 
 which is why it still identifies the invalid character at position 4
*/

begin
    execute immediate 'drop table charset_validation_test purge';
exception
    when others then
        if sqlcode != -942 then
            raise;
        end if;
end;
/

create table charset_validation_test (
    col1 nvarchar2(20),
    col2 clob
);

insert into charset_validation_test
values (
    unistr('foo\D800bar'),
    unistr('foo\D800bar')
);

commit;


prompt === VALIDATION OFFSETS ===

select
    utl_i18n.validate_character_encoding(col1)
        as invalid_offset_nvarchar2,
    utl_i18n.validate_character_encoding(col2)
        as invalid_offset_clob
from charset_validation_test;


prompt
prompt === DISPLAY THROUGH SQL CHARACTER TYPES ===

select
    asciistr(col1) as nvarchar2_value,
    asciistr(dbms_lob.substr(col2, 100, 1)) as clob_value
from charset_validation_test;


drop table charset_validation_test purge;
