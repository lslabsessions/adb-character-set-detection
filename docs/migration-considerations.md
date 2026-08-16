# AL32UTF8 Migration Considerations

This document focuses only on schema-length implications when moving to `AL32UTF8`. Character-set detection and conversion are covered in other documents.

## Single-byte and multibyte storage

`WE8MSWIN1252` is a single-byte character set.

`AL32UTF8` is a variable-width Unicode character set. The lab uses:

```sql
select
    utl_i18n.get_max_character_size('WE8MSWIN1252') as win1252_max_bytes,
    utl_i18n.get_max_character_size('AL32UTF8')     as al32utf8_max_bytes
from dual;
```

This highlights that an `AL32UTF8` character can require more than one byte.

## Example: `Desassociação`

In the `AL32UTF8` test database:

```sql
select
    length('Desassociação')  as character_length,
    lengthb('Desassociação') as byte_length
from dual;
```

returns:

```text
CHARACTER_LENGTH = 13
BYTE_LENGTH      = 15
```

Therefore these definitions have different practical limits:

```sql
varchar2(13 byte)
varchar2(13 char)
```

VARCHAR2(13 BYTE) limits the value to 13 bytes, while VARCHAR2(13 CHAR) allows up to 13 characters. In this AL32UTF8 example, Desassociação contains 13 characters but requires 15 bytes, so it fits in VARCHAR2(13 CHAR) but not in VARCHAR2(13 BYTE).

## `NLS_LENGTH_SEMANTICS`

When DDL omits an explicit qualifier:

```sql
varchar2(13)
```

the session setting `NLS_LENGTH_SEMANTICS` determines the default semantics for relevant definitions.

Check it with:

```sql
select parameter,
       value
from nls_session_parameters
where parameter = 'NLS_LENGTH_SEMANTICS';
```

It can be changed for the current session with:

```sql
alter session set nls_length_semantics = char;
```

## Prefer explicit semantics in controlled DDL

For application schemas maintained in source control, explicit definitions make the intention clear and avoid dependence on session defaults:

```sql
varchar2(13 char)
```

or:

```sql
varchar2(13 byte)
```

## Existing columns must be reviewed separately

Changing `NLS_LENGTH_SEMANTICS` does not retroactively change existing column definitions.

Useful metadata includes:

```sql
select
    table_name,
    column_name,
    data_length,
    char_length,
    char_used
from user_tab_columns;
```

`CHAR_USED` indicates character (`C`) or byte (`B`) semantics.

## Why this belongs in the lab

A correct conversion into `AL32UTF8` solves the encoding problem, but the target schema must still be large enough to store the converted characters.

This affects database migrations directly and can also affect integration tables that normalize data arriving from single-byte legacy sources.

## References

- Oracle AI Database 26ai — Choosing a Character Set  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/nlspg/choosing-character-set.html
- Oracle AI Database 26ai — `UTL_I18N.GET_MAX_CHARACTER_SIZE`  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/UTL_I18N.html
